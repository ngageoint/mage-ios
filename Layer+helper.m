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
#import "NSManagedObjectContext+Extra.h"

@implementation Layer (helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
   
    return self;
}

+ (id) layerForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Layer *layer = [[Layer alloc] initWithEntity:[NSEntityDescription entityForName:@"Layer" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
    [layer populateObjectFromJson:json];
    
    return layer;
}

+ (void) fetchFeatureLayersFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@?%@", @"https://magetpm.***REMOVED***", @"api/layers", @"type=Feature"];
    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSArray *layers = responseObject;
        
        for (id layer in layers) {
            NSLog(@"layer: %@", layer);
            Layer *l = [Layer layerForJson:layer inManagedObjectContext:context];

            NSSet *existingLayers = [context fetchObjectsForEntityName:@"Layer" withPredicate:@"(remoteId == %@)", l.remoteId];
            NSLog(@"existing layers is %@", existingLayers);
            // should only ever be one layer with the id so this will work fine
            Layer *dbLayer = [existingLayers anyObject];
            
            if (dbLayer != nil) {
                NSLog(@"Updating layer with id: %@", l.remoteId);
                [dbLayer populateObjectFromJson:layer];
            } else {
                NSLog(@"Inserting layer with id: %@", l.remoteId);
                [context insertObject:l];
            }
        }
        
        NSError *error = nil;
        if (! [context save:&error]) {
            NSLog(@"Error inserting Observation: %@", error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


@end
