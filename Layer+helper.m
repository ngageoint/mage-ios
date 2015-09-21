//
//  Layer+helper.m
//  mage-ios-sdk
//
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

NSString * const LayerFetched = @"mil.nga.giat.mage.layer.fetched";

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

+ (void) refreshLayersForEvent:(NSNumber *)eventId {
    [StaticLayer MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId]];
    [[HttpManager singleton].manager.operationQueue addOperation:[Layer operationToPullLayersForEvent:eventId success:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LayerFetched object:nil];
        NSArray *staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId]];
        for (StaticLayer *l in staticLayers) {
            NSOperation *fetchFeaturesOperation = [StaticLayer operationToFetchStaticLayerData:l];
            [[HttpManager singleton].manager.operationQueue addOperation:fetchFeaturesOperation];
        }
    } failure:^(NSError *error) {
        //code
    }]];
}

+ (NSOperation *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure {

    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/layers", [MageServer baseURL], eventId];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Layer request complete %@", responseObject);
            NSArray *layers = responseObject;
            
            NSMutableArray *layerRemoteIds = [[NSMutableArray alloc] init];
            
            for (id layer in layers) {
                NSString *remoteLayerId = [Layer layerIdFromJson:layer];
                [layerRemoteIds addObject:remoteLayerId];
                if ([[Layer layerTypeFromJson:layer] isEqualToString:@"Feature"]) {
                    [StaticLayer createOrUpdateStaticLayer:layer withEventId:eventId inContext:localContext];
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    return operation;
}

@end
