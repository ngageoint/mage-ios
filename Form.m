//
//  Form.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Form.h"
#import <AFNetworking.h>
#import "HttpManager.h"

@implementation Form

//- (id) populateObjectFromJson: (NSDictionary *) json {
//    [self setRemoteId:[json objectForKey:@"id"]];
//    [self setUserId:[json objectForKey:@"userId"]];
//    [self setDeviceId:[json objectForKey:@"deviceId"]];
//    
//    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    NSDate *date = [dateFormat dateFromString:[json objectForKey:@"lastModified"]];
//    [self setLastModified:date];
//    [self setUrl:[json objectForKey:@"url"]];
//    NSDictionary *jsonState = [json objectForKey: @"state"];
//    NSString *stateName = [jsonState objectForKey: @"name"];
//    State enumValue = [stateName StateEnumFromString];
//    [self setState:[NSNumber numberWithInt:(int)enumValue]];
//    
//    NSArray *coordinates = [json valueForKeyPath:@"geometry.coordinates"];
//    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[coordinates objectAtIndex:1] floatValue] longitude:[[coordinates objectAtIndex:0] floatValue]];
//    
//    [self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
//    
//    return self;
//}

//+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
//    
//    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
//    
//    [observation populateObjectFromJson:json];
//    
//    return observation;
//}

//+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
//    HttpManager *http = [HttpManager singleton];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];
//    NSString *url = [NSString stringWithFormat:@"%@/%@", serverUrl, @"FeatureServer/3/features"];
//    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSArray *features = [responseObject objectForKey:@"features"];
//        
//        for (id feature in features) {
//            Observation *o = [Observation observationForJson:feature inManagedObjectContext:context];
//            NSDictionary *properties = [feature objectForKey: @"properties"];
//            [o setProperties:properties];
//            
//            NSSet *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
//            Observation *dbObs = [existingObservations anyObject];
//            
//            //NSLog(@"there are %d observations", existingObservations.count);
//            int archive = [@"archive" IntFromStateEnum];
//            // if the Observation is archived and used to exist on this device, delete it
//            if ([o.state intValue] == archive && dbObs != nil) {
//                [context deleteObject:dbObs];
//                NSLog(@"Deleting observation with id: %@", o.remoteId);
//            }
//            // else if the observation is not archived and doesn't exist, insert it
//            else if ([o.state intValue] != archive && dbObs == nil) {
//                [context insertObject:o];
//                NSLog(@"Saving new observation with id: %@", o.remoteId);
//            }
//            // else if the observation is not archived, and not dirty and exists, update it
//            else if ([o.state intValue] != archive && [o.dirty boolValue]) {
//                [dbObs populateObjectFromJson:feature];
//                NSLog(@"Updating object with id: %@", o.remoteId);
//            }
//        }
//        
//        NSError *error = nil;
//        if (! [context save:&error]) {
//            NSLog(@"Error inserting Observation: %@", error);
//        }
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
//}
//

+ (NSOperation *) fetchFormInUseOperation {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];

    NSString* formId = [defaults objectForKey: @"formId"];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", serverUrl, @"api/forms", formId];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Form request complete");
        NSLog(@"form is %@", responseObject);
        [defaults setObject:responseObject forKey:@"form"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}


@end
