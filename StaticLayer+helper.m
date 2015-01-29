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

+ (void) refreshStaticLayers: (void (^) (BOOL success)) complete {
    NSArray *staticLayers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"type = %@", @"External"]];
    for (id layer in staticLayers) {
        [layer MR_deleteEntity];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/layers"];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"External", @"type", nil];
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: params error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Layer request complete %@", responseObject);
            NSArray *layers = responseObject;
            for (id layer in layers) {
                NSString *remoteLayerId = [StaticLayer layerIdFromJson:layer];
                StaticLayer *l = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteLayerId]];
                
                if (l == nil) {
                    l = [StaticLayer MR_createInContext:localContext];
                    [l populateObjectFromJson:layer];
                    NSLog(@"Inserting layer with id: %@", l.remoteId);
                } else {
                    NSLog(@"Updating layer with id: %@", l.remoteId);
                    [l populateObjectFromJson:layer];
                }
                NSOperation *fetchFeaturesOperation = [StaticLayer operationToFetchStaticLayerData:l];
                [[HttpManager singleton].manager.operationQueue addOperation:fetchFeaturesOperation];
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:StaticLayerLoaded object:nil];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    [operation start];
}

+ (NSOperation *) operationToFetchStaticLayerData: (StaticLayer *) layer {
    HttpManager *http = [HttpManager singleton];
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:[NSString stringWithFormat:@"%@/%@/%@/features", [MageServer baseURL], @"FeatureServer", layer.remoteId] parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            StaticLayer *localLayer = [layer MR_inContext:localContext];
            NSLog(@"fetched static features for %@", localLayer.name);
            localLayer.data = responseObject;
            localLayer.loaded = [NSNumber numberWithBool:YES];
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
