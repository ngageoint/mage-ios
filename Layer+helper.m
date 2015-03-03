//
//  Layer+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Layer+helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "Form.h"
#import "Observation+helper.h"
#import "MageServer.h"
#import "Server+helper.h"
#import "StaticLayer+helper.h"

@implementation Layer (helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setFormId:[json objectForKey:@"formId"]];
   
    return self;
}

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (NSString *) layerTypeFromJson:(NSDictionary *) json {
    return [json objectForKey:@"type"];
}

+ (NSOperation *) operationToPullLayers:(void (^) (BOOL success)) complete {

    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/layers"];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Layer request complete %@", responseObject);
            NSArray *layers = responseObject;
            for (id layer in layers) {
                NSString *remoteLayerId = [Layer layerIdFromJson:layer];
                if ([[Layer layerTypeFromJson:layer] isEqualToString:@"External"]) {
                    [StaticLayer createOrUpdateStaticLayer:layer];
                } else if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Feature"]) {
                    Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteLayerId]];
                    if (l == nil) {
                        l = [Layer MR_createEntityInContext:localContext];
                    }
                    [l populateObjectFromJson:layer];
                    
                    [Server setObservationFormId:l.formId];
                    [Server setObservationLayerId:l.remoteId];
                    
                    NSLog(@"Form id is %@", l.formId);
                }
            }
            
            complete(YES);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    return operation;
}

@end
