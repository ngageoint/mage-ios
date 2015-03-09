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

- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setFormId:[json objectForKey:@"formId"]];
    [self setEventId:eventId];
   
    return self;
}

+ (NSString *) layerIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (NSString *) layerTypeFromJson:(NSDictionary *) json {
    return [json objectForKey:@"type"];
}

+ (void) refreshLayersForEvent: (NSNumber *) eventId {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [Layer MR_truncateAllInContext:localContext];
        [StaticLayer MR_truncateAllInContext:localContext];
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSOperation *fetchlayersOperation = [Layer operationToPullLayersForEvent:eventId success: ^{
            NSLog(@"Saved layers for event");
        } failure:^{
            NSLog(@"Failed to save layers for event");
        }];
        [fetchlayersOperation start];
    }];
}

+ (NSOperation *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(void)) failure {

    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers", [MageServer baseURL], eventId];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Layer request complete %@", responseObject);
            NSArray *layers = responseObject;
            for (id layer in layers) {
                if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Feature"]) {
                    [StaticLayer createOrUpdateStaticLayer:layer withEventId:eventId];
                } else {
                    NSString *remoteLayerId = [Layer layerIdFromJson:layer];
                    Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteLayerId]];
                    if (l == nil) {
                        l = [Layer MR_createEntityInContext:localContext];
                        [l populateObjectFromJson:layer withEventId:eventId];
                        NSLog(@"Inserting layer with id: %@", l.remoteId);
                    } else {
                        NSLog(@"Updating layer with id: %@", l.remoteId);
                        [l populateObjectFromJson:layer withEventId:eventId];
                    }
                }
            }
            if (success != nil) {
                success();
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure != nil) {
            failure();
        }
    }];
    return operation;
}

@end
