//
//  Observation+Observation_helper.h
//  mage-ios-sdk
//
//

#import "Observation.h"
#import <CoreLocation/CoreLocation.h>
#import "GeoPoint.h"
#import "Attachment.h"

@interface Observation (helper)

+ (Observation *) observationWithLocation:(GeoPoint *) location inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (CLLocation *) location;

- (NSString *) sectionName;

+ (NSOperation*) operationToPullObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure;
+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;

@end
