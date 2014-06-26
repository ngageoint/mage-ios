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
    NSLog(@"coordinate array: %@", coordinates);
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[coordinates objectAtIndex:1] floatValue] longitude:[[coordinates objectAtIndex:0] floatValue]];
    
    [self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
    
    return self;
}

+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
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
            //NSLog(@"state is: %@", o.state);
            NSDictionary *properties = [feature objectForKey: @"properties"];
            for (NSString* property in properties) {
                //NSLog(@"property json is: %@ value is: %@", property, properties[property]);
                ObservationProperty *prop = [ObservationProperty initWithKey:property andValue:properties[property] inManagedObjectContext:context];
                [o addPropertiesObject:prop];
            }
            
            NSSet *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
            //NSLog(@"there are %d observations", existingObservations.count);
            int archive = [@"archive" IntFromStateEnum];
            // if the Observation is archived and used to exist on this device, delete it
            if ([o.state intValue] == archive && existingObservations.count != 0) {
                [context deleteObject:o];
                NSLog(@"Deleting observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived and doesn't exist, insert it
            else if ([o.state intValue] != archive && existingObservations.count == 0) {
                [context insertObject:o];
                NSLog(@"Saving new observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived, and not dirty and exists, update it
            else if ([o.state intValue] != archive && [o.dirty boolValue]) {
                [o populateObjectFromJson:feature];
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
}

@end
