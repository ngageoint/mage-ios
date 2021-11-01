//
//  StaticLayer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "StaticLayer.h"

#import "MageSessionManager.h"
#import "MageServer.h"

@implementation StaticLayer

NSString * const StaticLayerLoaded = @"mil.nga.giat.mage.static.layer.loaded";

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (void) createOrUpdateStaticLayer: (id) layer withEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSString *remoteLayerId = [StaticLayer layerIdFromJson:layer];
    StaticLayer *l = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId] inContext:context];
    if (l == nil) {
        l = [StaticLayer MR_createEntityInContext:context];
        [l populateObjectFromJson:layer withEventId:eventId];
        l.loaded = [NSNumber numberWithFloat: OFFLINE_LAYER_NOT_DOWNLOADED];
        NSLog(@"Inserting layer with id: %@ into event: %@", l.remoteId, eventId);
    } else {
        NSLog(@"Updating layer with id: %@ into event: %@", l.remoteId, eventId);
        [l populateObjectFromJson:layer withEventId:eventId];
    }
    NSLog(@"layer loaded %@ ? %@", l.name, l.loaded);
    if (l.loaded) {
        [StaticLayer fetchStaticLayerData:eventId layer:l];
    }
}

+ (void) fetchStaticLayerData: (NSNumber *)eventId layer: (StaticLayer *) staticLayer {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *fetchFeaturesTask = [StaticLayer operationToFetchStaticLayerData:staticLayer];
    [manager addTask:fetchFeaturesTask];
}

+ (NSURLSessionDataTask *) operationToFetchStaticLayerData: (StaticLayer *) layer {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    __block NSNumber *layerId = layer.remoteId;
    __block NSNumber *eventId = layer.eventId;
    
    // put this line back when the event endpoint returns the proper url for the layer
    //NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/features", layer.url]];
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/events/%@/layers/%@/features", [MageServer baseURL], eventId, layerId]];
    NSURLSessionDataTask * task = [manager GET_TASK:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        StaticLayer *fetchedLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", layerId, eventId]];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            StaticLayer *localLayer = [fetchedLayer MR_inContext:localContext];
            NSLog(@"fetched static features for %@", localLayer.name);
            NSMutableDictionary *dictionaryResponse = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)responseObject, kCFPropertyListMutableContainers));
            
            for (NSDictionary *feature in [dictionaryResponse objectForKey:@"features"]) {
                NSString *iconUrl = [feature valueForKeyPath:@"properties.style.iconStyle.icon.href"];
                if (iconUrl && [iconUrl hasPrefix:@"https"]) {
                    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
                    NSString *featureIconRelativePath = [NSString stringWithFormat:@"featureIcons/%@/%@", localLayer.remoteId, [feature valueForKey:@"id"]];
                    NSString *featureIconPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, featureIconRelativePath];
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:iconUrl]];
                    
                    NSError *error;
                    if (![[NSFileManager defaultManager] fileExistsAtPath:featureIconPath])
                        [[NSFileManager defaultManager] createDirectoryAtPath:[featureIconPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
                    
                    [imageData writeToFile:featureIconPath atomically:YES];
                    [feature setValue:featureIconRelativePath forKeyPath:@"properties.style.iconStyle.icon.href"];
                }
            }
            localLayer.data = dictionaryResponse;
            localLayer.loaded = [NSNumber numberWithFloat: OFFLINE_LAYER_LOADED];
            localLayer.downloading = nil;
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (contextDidSave) {
                StaticLayer *localLayer = [layer MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSNotificationCenter defaultCenter] postNotificationName:StaticLayerLoaded object:localLayer];
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Layer *localLayer = [layer MR_inContext:localContext];
        
        localLayer.downloading = YES;
    }];
    
    return task;
}

- (void) removeStaticLayerData {
    __weak typeof(self) weakSelf = self;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        StaticLayer *localLayer = [weakSelf MR_inContext:localContext];
        localLayer.loaded = [NSNumber numberWithFloat: OFFLINE_LAYER_NOT_DOWNLOADED];
        localLayer.data = nil;
    } completion:^(BOOL contextDidSave, NSError *error) {
   }];
}

@end
