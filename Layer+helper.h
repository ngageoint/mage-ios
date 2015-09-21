//
//  Layer+helper.h
//  mage-ios-sdk
//
//

#import "Layer.h"

@interface Layer (helper)

extern NSString * const LayerFetched;

+ (NSString *) layerTypeFromJson:(NSDictionary *) json;
- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId;
+ (NSOperation *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure;
+ (void) refreshLayersForEvent: (NSNumber *) eventId;

@end
