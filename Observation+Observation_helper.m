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
        
        for (id feature in features) {
            Observation *o = [Observation initWithJson:feature inManagedObjectContext:context];
            NSLog(@"url is: %@", o.url);
            for (id property in [feature objectForKey: @"properties"]) {
                NSLog(@"property json is: %@", property);
                ObservationProperty *prop = [ObservationProperty initWithJson:property inManagedObjectContext:context];
                
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
