//
//  StaticLayer+helper.h
//  mage-ios-sdk
//
//

#import "StaticLayer.h"

@interface StaticLayer (helper)

extern NSString * const StaticLayerLoaded;

+ (NSOperation *) operationToFetchStaticLayerData: (StaticLayer *) layer;
+ (void) createOrUpdateStaticLayer: (id) layer withEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context;

@end
