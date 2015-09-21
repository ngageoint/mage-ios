//
//  GPSLocation+helper.h
//  mage-ios-sdk
//
//

#import "GPSLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface GPSLocation (helper)

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSArray *) fetchGPSLocationsInManagedObjectContext:(NSManagedObjectContext *) context;
+ (NSArray *) fetchLastXGPSLocations: (NSUInteger) x;

+ (NSOperation *) operationToPushGPSLocations: (NSArray *) locations success: (void (^)()) success failure: (void (^)(NSError *)) failure;

@end
