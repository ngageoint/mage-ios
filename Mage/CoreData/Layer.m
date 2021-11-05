//
//  Layer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Layer.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "StaticLayer.h"
#import "ImageryLayer.h"
#import "MAGE-Swift.h"

@implementation Layer

NSString * const GeoPackageDownloaded = @"mil.nga.giat.mage.geopackage.downloaded";
float const OFFLINE_LAYER_LOADED = 1;
float const EXTERNAL_LAYER_LOADED = .5;
float const OFFLINE_LAYER_NOT_DOWNLOADED = 0;
float const EXTERNAL_LAYER_PROCESSING = -1;

- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setFormId:[json objectForKey:@"formId"]];
    [self setFile:[json objectForKey:@"file"]];
    [self setEventId:eventId];
    
    return self;
}

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (NSString *) layerTypeFromJson:(NSDictionary *) json {
    return [json objectForKey:@"type"];
}

+ (void) refreshLayersForEvent:(NSNumber *)eventId {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [Layer operationToPullLayersForEvent:eventId success:^{
    } failure:^(NSError *error) {
    }];
    [manager addTask:task];
}

+ (void) cancelGeoPackageDownload: (Layer *) layer {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    for (NSURLSessionDownloadTask *task in manager.downloadTasks) {
        if ([task.taskDescription isEqualToString: [NSString stringWithFormat: @"geopackage_download_%@", layer.remoteId]]) {
            [task cancel];
        }
    }
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Layer *localLayer = [layer MR_inContext:localContext];
        localLayer.downloadedBytes = 0;
        localLayer.downloading = NO;
    }];
}

+ (void) downloadGeoPackage: (Layer *) layer success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers/%@", [MageServer baseURL], [Server currentEventId], [layer remoteId]];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"/geopackages/%@/%@", layer.remoteId, [layer.file valueForKey:@"name"]]];
    
    stringPath = [NSString stringWithFormat:@"%@_%@_%@.gpkg", [[stringPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[stringPath lastPathComponent] stringByDeletingPathExtension]], layer.remoteId, @"from_server"];
    
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    [request setValue:[layer.file valueForKey:@"contentType"] forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Layer *localLayer = [layer MR_inContext:localContext];
            
            localLayer.downloadedBytes = [NSNumber numberWithUnsignedLongLong: downloadProgress.completedUnitCount];
        }];
        NSLog(@"downloaded Bytes: %lld", downloadProgress.completedUnitCount);

    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:stringPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (success) {
            success();
        }
        if (error) {
            NSLog(@"Error: %@", error);
            if (failure) {
                failure(error);
            }
            return;
        }
        NSString *fileString = [filePath path];
        NSLog(@"Downloaded GeoPackage to %@", fileString);
        [[NSNotificationCenter defaultCenter] postNotificationName:GeoPackageDownloaded object:nil userInfo:@{@"filePath": fileString, @"layerId": layer.remoteId}];
    }];
    
    task.taskDescription = [NSString stringWithFormat: @"geopackage_download_%@", layer.remoteId];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:stringPath]) {
        NSLog(@"Create directory %@ for geopackage", [stringPath stringByDeletingLastPathComponent]);
        [[NSFileManager defaultManager] createDirectoryAtPath:[stringPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    } else {
        NSLog(@"GeoPackage still exists at %@, delete it", stringPath);
        [[NSFileManager defaultManager] removeItemAtPath:stringPath error:&error];
        if (error) {
            NSLog(@"Error deleting existing GeoPackage %@", error);
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:stringPath]) {
            NSLog(@"GeoPackage file still exists at %@ after attempted deletion", stringPath);
        }
    }
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Layer *localLayer = [layer MR_inContext:localContext];
        
        localLayer.downloading = YES;
    }];
        
    [manager addTask:task];
}

+ (NSMutableArray *) populateLayersFromJson: (NSArray *) layers inEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSMutableArray *layerRemoteIds = [[NSMutableArray alloc] init];
    for (id layer in layers) {
        NSString *remoteLayerId = [Layer layerIdFromJson:layer];
        [layerRemoteIds addObject:remoteLayerId];
        if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Feature"]) {
            [StaticLayer createOrUpdateStaticLayer:layer withEventId:eventId inContext:context];
        } else if ([[Layer layerTypeFromJson:layer] isEqualToString:@"GeoPackage"]) {
            Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:context];
            if (l == nil) {
                l = [Layer MR_createEntityInContext:context];
                l.loaded = [NSNumber numberWithFloat: OFFLINE_LAYER_NOT_DOWNLOADED];
            }
            [l populateObjectFromJson:layer withEventId:eventId];
            
            // If this layer already exists but for a different event, set it's downloaded status
            Layer *existing = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId != %@", remoteLayerId, eventId] inContext:context];
            if (existing) {
                l.loaded = existing.loaded;
            }
        } else if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Imagery"]){
            ImageryLayer *l = [ImageryLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:context];
            if (l == nil) {
                l = [ImageryLayer MR_createEntityInContext:context];
            }
            [l populateObjectFromJson:layer withEventId:eventId];
        } else {
            Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:context];
            if (l == nil) {
                l = [Layer MR_createEntityInContext:context];
            }
            [l populateObjectFromJson:layer withEventId:eventId];
        }
    }
    return layerRemoteIds;
}

+ (NSURLSessionDataTask *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers", [MageServer baseURL], eventId];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSMutableArray *layerRemoteIds = [Layer populateLayersFromJson:responseObject inEventId: eventId inContext:localContext];
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [Layer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND eventId == %@", layerRemoteIds, eventId] inContext:localContext];
            NSMutableDictionary *selectedOnlineLayers = [[standardUserDefaults objectForKey:@"selectedOnlineLayers"] mutableCopy];
            
            // get the currently selected online layers, remove all existing layers and then delete the ones that are left
            NSMutableArray *removedSelectedOnlineLayers = [[selectedOnlineLayers objectForKey:[[Server currentEventId] stringValue]] mutableCopy];
            [removedSelectedOnlineLayers removeObjectsInArray:layerRemoteIds];
            
            NSMutableArray *selectedEventOnlineLayers = [[selectedOnlineLayers objectForKey:[[Server currentEventId] stringValue]] mutableCopy];
            [selectedEventOnlineLayers removeObjectsInArray:removedSelectedOnlineLayers];
            if (selectedEventOnlineLayers) {
                [selectedOnlineLayers setObject:selectedEventOnlineLayers forKey:[[Server currentEventId] stringValue]];
            }
            if (selectedOnlineLayers) {
                [standardUserDefaults setObject:selectedOnlineLayers forKey:@"selectedOnlineLayers"];
            }
            
            [StaticLayer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND eventId == %@", layerRemoteIds, eventId] inContext:localContext];
            NSMutableDictionary *selectedStaticLayers = [[standardUserDefaults objectForKey:@"selectedStaticLayers"] mutableCopy];
            
            // get the currently selected online layers, remove all existing layers and then delete the ones that are left
            NSMutableArray *removedSelectedStaticLayers = [[selectedStaticLayers objectForKey:[[Server currentEventId] stringValue]] mutableCopy];
            [removedSelectedStaticLayers removeObjectsInArray:layerRemoteIds];
            
            NSMutableArray *selectedEventStaticLayers = [[selectedStaticLayers objectForKey:[[Server currentEventId] stringValue]] mutableCopy];
            if (selectedEventStaticLayers == nil) {
                selectedEventStaticLayers = [[NSMutableArray alloc] init];
            }
            [selectedEventStaticLayers removeObjectsInArray:removedSelectedStaticLayers];
            [selectedStaticLayers setObject:selectedEventStaticLayers forKey:[[Server currentEventId] stringValue]];
            
            [standardUserDefaults setObject:selectedStaticLayers forKey:@"selectedStaticLayers"];
            [standardUserDefaults synchronize];
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                success();
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}
@end
