//
//  StaticLayer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "StaticLayer.h"

#import "HttpManager.h"
#import "MageServer.h"

@implementation StaticLayer

NSString * const StaticLayerLoaded = @"mil.nga.giat.mage.static.layer.loaded";

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (void) createOrUpdateStaticLayer: (id) layer withEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSString *remoteLayerId = [StaticLayer layerIdFromJson:layer];
    StaticLayer *l = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteLayerId, eventId]];
    if (l == nil) {
        l = [StaticLayer MR_createEntityInContext:context];
        [l populateObjectFromJson:layer withEventId:eventId];
        NSLog(@"Inserting layer with id: %@ into event: %@", l.remoteId, eventId);
    } else {
        NSLog(@"Updating layer with id: %@ into event: %@", l.remoteId, eventId);
        [l populateObjectFromJson:layer withEventId:eventId];
    }
}

+ (NSOperation *) operationToFetchStaticLayerData: (StaticLayer *) layer {
    HttpManager *http = [HttpManager singleton];
    __block NSNumber *layerId = layer.remoteId;
    __block NSNumber *eventId = layer.eventId;
    
    // put this line back when the event endpoint returns the proper url for the layer
    //    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/features", layer.url] parameters: nil error: nil];
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/api/events/%@/layers/%@/features", [MageServer baseURL], eventId, layerId] parameters: nil error: nil];
    
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        StaticLayer *fetchedLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", layerId, eventId]];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            StaticLayer *localLayer = [fetchedLayer MR_inContext:localContext];
            NSLog(@"fetched static features for %@", localLayer.name);
            NSMutableDictionary *dictionaryResponse = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)responseObject, kCFPropertyListMutableContainers));
            
            localLayer.loaded = [NSNumber numberWithBool:YES];
            for (NSDictionary *feature in [dictionaryResponse objectForKey:@"features"]) {
                NSString *iconUrl = [feature valueForKeyPath:@"properties.style.iconStyle.icon.href"];
                if (iconUrl) {
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
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (contextDidSave) {
                StaticLayer *localLayer = [layer MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSNotificationCenter defaultCenter] postNotificationName:StaticLayerLoaded object:localLayer];
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
    
}

@end
