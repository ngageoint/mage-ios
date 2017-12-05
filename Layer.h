//
//  Layer.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Layer : NSManagedObject

extern NSString * const LayerFetched;

+ (NSString *) layerTypeFromJson:(NSDictionary *) json;
- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId;
+ (NSURLSessionDataTask *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure;
+ (void) refreshLayersForEvent: (NSNumber *) eventId;

@end

NS_ASSUME_NONNULL_END

#import "Layer+CoreDataProperties.h"
