//
//  StaticLayer+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 1/23/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "StaticLayer.h"

@interface StaticLayer (helper)

extern NSString * const StaticLayerLoaded;

+ (void) refreshStaticLayers: (void (^) (BOOL success)) complete;
+ (NSOperation *) operationToFetchStaticLayerData: (StaticLayer *) layer;

@end
