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
#import "Server.h"

@implementation Layer

NSString * const LayerFetched = @"mil.nga.giat.mage.layer.fetched";
NSString * const GeoPackageLayerFetched = @"mil.nga.giat.mage.geopackage.layer.fetched";
NSString * const GeoPackageDownloaded = @"mil.nga.giat.mage.geopackage.downloaded";

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
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [Layer operationToPullLayersForEvent:eventId success:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LayerFetched object:nil];
        NSArray *staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId]];
        for (StaticLayer *l in staticLayers) {
            NSURLSessionDataTask *fetchFeaturesTask = [StaticLayer operationToFetchStaticLayerData:l];
            [manager addTask:fetchFeaturesTask];
        }
    } failure:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LayerFetched object:nil];
    }];
    [manager addTask:task];
}

+ (void) downloadGeoPackage: (Layer *) layer success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers/%@", [MageServer baseURL], [Server currentEventId], [layer remoteId]];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"/geopackages/%@/%@", layer.remoteId, [layer.file valueForKey:@"name"]]];
    
    stringPath = [NSString stringWithFormat:@"%@_%@_%@.gpkg", [[stringPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[stringPath lastPathComponent] stringByDeletingPathExtension]], layer.remoteId, @"from_server"];
    
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    [request setValue:[layer.file valueForKey:@"contentType"] forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Layer *localLayer = [layer MR_inContext:localContext];
            
            localLayer.downloadedBytes = [NSNumber numberWithUnsignedLongLong: downloadProgress.completedUnitCount];
        }];
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

+ (NSURLSessionDataTask *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers", [MageServer baseURL], eventId];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Seems like we shouldn't have to do this....
            [StaticLayer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId] inContext:localContext];
            
            NSArray *layers = responseObject;
            
            NSMutableArray *layerRemoteIds = [[NSMutableArray alloc] init];
            
            for (id layer in layers) {
                NSString *remoteLayerId = [Layer layerIdFromJson:layer];
                [layerRemoteIds addObject:remoteLayerId];
                if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Feature"]) {
                    [StaticLayer createOrUpdateStaticLayer:layer withEventId:eventId inContext:localContext];
                } else if ([[Layer layerTypeFromJson:layer] isEqualToString:@"GeoPackage"]) {
                    Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:localContext];
                    if (l == nil) {
                        l = [Layer MR_createEntityInContext:localContext];
                        [l populateObjectFromJson:layer withEventId:eventId];
                        NSLog(@"Inserting layer with id: %@ in event: %@", l.remoteId, eventId);
                    } else {
                        NSLog(@"Updating layer with id: %@ in event: %@", l.remoteId, eventId);
                        [l populateObjectFromJson:layer withEventId:eventId];
                    }
                    
                    // If this layer already exists but for a different event, set it's downloaded status
                    Layer *existing = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId != %@", remoteLayerId, eventId] inContext:localContext];
                    if (existing) {
                        l.loaded = existing.loaded;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:GeoPackageLayerFetched object:l];
                } else {
                    Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:localContext];
                    if (l == nil) {
                        l = [Layer MR_createEntityInContext:localContext];
                        [l populateObjectFromJson:layer withEventId:eventId];
                        NSLog(@"Inserting layer with id: %@ in event: %@", l.remoteId, eventId);
                    } else {
                        NSLog(@"Updating layer with id: %@ in event: %@", l.remoteId, eventId);
                        [l populateObjectFromJson:layer withEventId:eventId];
                    }
                }
            }
            [Layer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND eventId == %@", layerRemoteIds, eventId] inContext:localContext];
            [StaticLayer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND eventId == %@", layerRemoteIds, eventId] inContext:localContext];
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
