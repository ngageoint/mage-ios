//
//  LocationService.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const kReportLocationKey;
extern NSString * const kGPSDistanceFilterKey;
extern NSString * const kLocationReportingFrequencyKey;

@interface LocationService : NSObject<CLLocationManagerDelegate>

+ (instancetype) singleton;

- (void) start: (NSManagedObjectContext *) context;
- (void) stop;

- (CLLocation *) location;
@property (nonatomic) BOOL started;

@end
