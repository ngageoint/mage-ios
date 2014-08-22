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
#import "Form.h"
#import "Observation+helper.h"

@implementation Layer (helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setFormId:[json objectForKey:@"formId"]];
   
    return self;
}

+ (id) layerForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Layer *layer = [[Layer alloc] initWithEntity:[NSEntityDescription entityForName:@"Layer" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
    [layer populateObjectFromJson:json];
    
    return layer;
}

+ (NSOperation *) pullFeatureLayersWithManagedObjectContext: (NSManagedObjectContext *) context {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];
    NSString *url = [NSString stringWithFormat:@"%@/%@", serverUrl, @"api/layers"];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"Feature", @"type", nil];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: params error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Layer request complete %@", responseObject);
        NSArray *layers = responseObject;
        for (id layer in layers) {
            Layer *l = [Layer layerForJson:layer inManagedObjectContext:context];
            [defaults setObject:l.formId forKey:@"formId"];
            [defaults setObject:l.remoteId forKey:@"layerId"];
            [defaults synchronize];
            NSLog(@"Form id is %@", l.formId);
            
            NSSet *existingLayers = [context fetchObjectsForEntityName:@"Layer" withPredicate:@"(remoteId == %@)", l.remoteId];
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
        
        NSOperation* formOp = [Form fetchFormInUseOperation];
        NSOperation* observationOp = [Observation fetchObservationsFromServerWithManagedObjectContext:context];
        [observationOp addDependency:formOp];
        [http.manager.operationQueue addOperations:@[formOp, observationOp] waitUntilFinished: NO];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}


@end
