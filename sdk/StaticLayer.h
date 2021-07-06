//
//  StaticLayer.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Layer.h"

NS_ASSUME_NONNULL_BEGIN

@interface StaticLayer : Layer

extern NSString * const StaticLayerLoaded;

+ (NSURLSessionDataTask *) operationToFetchStaticLayerData: (StaticLayer *) layer;
+ (void) createOrUpdateStaticLayer: (id) layer withEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context;
+ (void) fetchStaticLayerData: (NSNumber *)eventId layer: (StaticLayer *) staticLayer;
- (void) removeStaticLayerData;

@end

NS_ASSUME_NONNULL_END

#import "StaticLayer+CoreDataProperties.h"
