//
//  StaticLayer+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 1/23/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "StaticLayer+helper.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "Layer+helper.h"

@implementation StaticLayer (helper)

NSString * const StaticLayerLoaded = @"mil.nga.giat.mage.static.layer.loaded";

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (void) refreshStaticLayers {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [StaticLayer MR_truncateAllInContext:localContext];
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSOperation *fetchlayersOperation = [StaticLayer operationtoFetchStaticLayers];
        [fetchlayersOperation start];
    }];
}

+ (void) createOrUpdateStaticLayer: (id) layer {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSString *remoteLayerId = [StaticLayer layerIdFromJson:layer];
        StaticLayer *l = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteLayerId]];
        if (l == nil) {
            l = [StaticLayer MR_createEntityInContext:localContext];
            [l populateObjectFromJson:layer];
            NSLog(@"Inserting layer with id: %@", l.remoteId);
            NSOperation *fetchFeaturesOperation = [StaticLayer operationToFetchStaticLayerData:l];
            [[HttpManager singleton].manager.operationQueue addOperation:fetchFeaturesOperation];
        } else {
            NSLog(@"Updating layer with id: %@", l.remoteId);
            [l populateObjectFromJson:layer];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:StaticLayerLoaded object:nil];
    }];
}

+ (NSOperation *) operationtoFetchStaticLayers {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/layers"];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"External", @"type", nil];
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: params error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *layers = responseObject;
        for (id layer in layers) {
            [StaticLayer createOrUpdateStaticLayer:layer];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}

+ (NSOperation *) operationToFetchStaticLayerData: (StaticLayer *) layer {
    HttpManager *http = [HttpManager singleton];
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/%@/%@/features", [MageServer baseURL], @"FeatureServer", layer.remoteId] parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            StaticLayer *localLayer = [layer MR_inContext:localContext];
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
