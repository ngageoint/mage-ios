//
//  GPSLocation+helper.m
//  mage-ios-sdk
//
//

#import "GPSLocation+helper.h"
#import "HttpManager.h"
#import "NSDate+Iso8601.h"
#import "GeoPoint.h"
#import "MageServer.h"
#import "Server+helper.h"

@implementation GPSLocation (helper)

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    GPSLocation *gpsLocation = [GPSLocation MR_createEntityInContext:managedObjectContext];
    
    gpsLocation.geometry = [[GeoPoint alloc] initWithLocation:location];
    gpsLocation.timestamp = location.timestamp;
    gpsLocation.eventId = [Server currentEventId];
    gpsLocation.properties = @{
        @"altitude": [NSNumber numberWithDouble:location.altitude],
        @"accuracy": [NSNumber numberWithDouble:location.horizontalAccuracy],
        @"verticalAccuracy": [NSNumber numberWithDouble:location.verticalAccuracy],
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

+ (NSOperation *) operationToPushGPSLocations:(NSArray *) locations success:(void (^)()) success failure: (void (^)(NSError *)) failure {
	NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/locations", [MageServer baseURL], [Server currentEventId]];
	NSLog(@"Trying to push locations to server %@", url);
    
    NSLog(@"Got these locations to push %@", [locations description]);

	
    HttpManager *http = [HttpManager singleton];
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (GPSLocation *location in locations) {
        GeoPoint *point = location.geometry;
        
        NSLog(@"About to push  this point to server %.20f, %.20f", point.location.coordinate.latitude, point.location.coordinate.longitude);
        
        [parameters addObject:@{
            @"geometry": @{
                @"type": @"Point",
                @"coordinates": @[[NSNumber numberWithDouble:point.location.coordinate.longitude], [NSNumber numberWithDouble:point.location.coordinate.latitude]]
            },
            @"properties": [NSDictionary dictionaryWithDictionary:location.properties]
        }];
    }
    
    NSLog(@"Parameters %@", [parameters description]);
    
    NSMutableURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:parameters error: nil];
    AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id response) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Failed to push location after entering background");
    }];
    
    return operation;
}

@end
