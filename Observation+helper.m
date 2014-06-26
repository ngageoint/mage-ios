//
//  Observation+Observation_helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "ObservationProperty+helper.h"
#import "MageEnums.h"

@implementation Observation (Observation_helper)

//typedef enum {
//    Archive = 0,
//    Active = 1
//} State;
//
//-(State) stateRaw {
//    return (State)[[self state] intValue];
//}
//
//-(void)setStateRaw:(State)type {
//    [self setState:[NSNumber numberWithInt:type]];
//}

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
        return self;
    }

+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
//    Observation *observation = (Observation*)[NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:nil];
    
    [observation populateObjectFromJson:json];
    
    return observation;
}

+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", @"https://magetpm.***REMOVED***", @"FeatureServer/3/features"];
    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        NSArray *features = [responseObject objectForKey:@"features"];

        for (id feature in features) {
            Observation *o = [Observation observationForJson:feature inManagedObjectContext:context];
            //NSLog(@"feature is: %@", feature);
            //NSLog(@"feature properties: %@", [feature objectForKey: @"properties"]);
            NSLog(@"state is: %@", o.state);
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
                [context insertObject:o];
                NSLog(@"New observation, saving");
                
            } else {
                NSLog(@"Not new, ignore for now: %@", o.remoteId);
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
