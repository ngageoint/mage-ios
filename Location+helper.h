//
//  Location+helper.h
//  mage-ios-sdk
//
//

#import "Location.h"
#import "Geometry.h"
#import <CoreLocation/CoreLocation.h>

@interface Location (helper)

//+ (Location *) locationForJson: (NSDictionary *) json;

-(CLLocation *) location;

- (NSString *) sectionName;

- (void) populateLocationFromJson:(NSArray *) locations;

+ (NSOperation *) operationToPullLocationsWithSuccess: (void (^)()) success failure: (void (^)(NSError *)) failure;

@property (nonatomic, retain) Geometry* geometry;

@end
