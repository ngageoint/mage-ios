//
//  Observation+Observation_helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+helper.h"
#import "HttpManager.h"
#import "MageEnums.h"
#import "GeoPoint.h"

@implementation Observation (Observation_helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setUserId:[json objectForKey:@"userId"]];
    [self setDeviceId:[json objectForKey:@"deviceId"]];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    NSDate *date = [dateFormat dateFromString:[json objectForKey:@"lastModified"]];
    [self setLastModified:date];
    [self setUrl:[json objectForKey:@"url"]];
    NSDictionary *jsonState = [json objectForKey: @"state"];
    NSString *stateName = [jsonState objectForKey: @"name"];
    State enumValue = [stateName StateEnumFromString];
    [self setState:[NSNumber numberWithInt:(int)enumValue]];
    
    NSArray *coordinates = [json valueForKeyPath:@"geometry.coordinates"];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[coordinates objectAtIndex:1] floatValue] longitude:[[coordinates objectAtIndex:0] floatValue]];
    
    [self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
    
    return self;
}

+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
    [observation populateObjectFromJson:json];
    
    return observation;
}

+ (NSOperation*) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];
    NSString *layerId = [defaults stringForKey:@"layerId"];
    NSString *url = [NSString stringWithFormat:@"%@/FeatureServer/%@/features", serverUrl, layerId];
    NSLog(@"Fetching from layer %@", layerId);
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Observation request complete");
        NSArray *features = [responseObject objectForKey:@"features"];
        
        for (id feature in features) {
            Observation *o = [Observation observationForJson:feature inManagedObjectContext:context];
            NSDictionary *properties = [feature objectForKey: @"properties"];
            [o setProperties:properties];
            
            NSSet *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
            Observation *dbObs = [existingObservations anyObject];
            
            //NSLog(@"there are %d observations", existingObservations.count);
            int archive = [@"archive" IntFromStateEnum];
            // if the Observation is archived and used to exist on this device, delete it
            if ([o.state intValue] == archive && dbObs != nil) {
                [context deleteObject:dbObs];
                NSLog(@"Deleting observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived and doesn't exist, insert it
            else if ([o.state intValue] != archive && dbObs == nil) {
                [context insertObject:o];
                NSLog(@"Saving new observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived, and not dirty and exists, update it
            else if ([o.state intValue] != archive && [o.dirty boolValue]) {
                [dbObs populateObjectFromJson:feature];
                NSLog(@"Updating object with id: %@", o.remoteId);
            }
        }
        
        NSError *error = nil;
        if (! [context save:&error]) {
            NSLog(@"Error inserting Observation: %@", error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    return operation;
}

@end
