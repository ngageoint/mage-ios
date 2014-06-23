//
//  Observation+Observation_helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+Observation_helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "ObservationProperty+helper.h"

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
        return self;
    }

+ (id) initWithJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Observation *observation = (Observation*)[NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:context];
    
    [observation populateObjectFromJson:json];
    
    return observation;
}

+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", @"https://magetpm.***REMOVED***", @"FeatureServer/3/features"];
    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        NSArray *features = [responseObject objectForKey:@"features"];
        
        NSArray *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", @"5388d287d9ec70c43e000b94"];
        NSLog(@"there are %d observations", existingObservations.count);
        NSLog(@"obs %@", existingObservations);

        
        for (id feature in features) {
            Observation *o = [Observation initWithJson:feature inManagedObjectContext:context];
            NSLog(@"url is: %@", o.url);
            NSLog(@"feature properties: %@", [feature objectForKey: @"properties"]);
            NSDictionary *properties = [feature objectForKey: @"properties"];
            for (NSString* property in properties) {
                NSLog(@"property json is: %@ value is: %@", property, properties[property]);
                ObservationProperty *prop = [ObservationProperty initWithKey:property andValue:properties[property] inManagedObjectContext:context];
                [o addPropertiesObject:prop];
            }
            
            NSArray *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
            NSLog(@"there are %d observations", existingObservations.count);
            NSLog(@"obs %@", existingObservations);
            if (existingObservations.count == 0) {
                NSLog(@"New observation, saving");
                NSError *error = nil;
                if (! [context save:&error]) {
                    NSLog(@"Error inserting Observation: %@", error);
                }
            } else {
                NSLog(@"Not new, ignore for now: %@", o.remoteId);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
