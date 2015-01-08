//
//  GPSLocation+helper.m
//  mage-ios-sdk
//
//  Created by William Newman on 8/20/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GPSLocation+helper.h"
#import "HttpManager.h"
#import "NSDate+Iso8601.h"
#import "GeoPoint.h"
#import "MageServer.h"

@implementation GPSLocation (helper)

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    GPSLocation *gpsLocation = [GPSLocation MR_createInContext:managedObjectContext];
    
    gpsLocation.geometry = [[GeoPoint alloc] initWithLocation:location];
    gpsLocation.timestamp = location.timestamp;
    gpsLocation.properties = @{
        @"altitude": [NSNumber numberWithDouble:location.altitude],
        @"accuracy": [NSNumber numberWithDouble:location.horizontalAccuracy],
        @"bearing": [NSNumber numberWithDouble:location.course],
        @"speed": [NSNumber numberWithDouble:location.speed],
        @"timestamp": [location.timestamp iso8601String]
    };
    
    return gpsLocation;
}

+ (NSArray *) fetchGPSLocationsInManagedObjectContext:(NSManagedObjectContext *) context {
    return [GPSLocation MR_findAllSortedBy:@"timestamp" ascending:YES inContext:context];
}

+ (NSArray *) fetchLastXGPSLocations: (NSUInteger) limit {
    NSFetchRequest *fetchRequest = [GPSLocation MR_requestAllSortedBy:@"timestamp" ascending:YES];
    fetchRequest.fetchLimit = limit;
    
    return [GPSLocation MR_executeFetchRequest:fetchRequest];
}

+ (NSOperation *) operationToPushGPSLocations:(NSArray *) locations success:(void (^)()) success failure: (void (^)()) failure {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/locations/"];
	NSLog(@"Trying to push locations to server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (GPSLocation *location in locations) {
        GeoPoint *point = location.geometry;
        [parameters addObject:@{
            @"geometry": @{
                @"type": @"Point",
                @"coordinates": @[[NSNumber numberWithDouble:point.location.coordinate.longitude], [NSNumber numberWithDouble:point.location.coordinate.latitude]]
            },
            @"properties": location.properties
        }];
    }
    
    NSMutableURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:parameters error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id response) {
        success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        failure();
    }];
    
    return operation;
}

@end
