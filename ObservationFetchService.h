//
//  ObservationFetchService.h
//  mage-ios-sdk
//
//  Created by William Newman on 8/22/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const kObservationFetchFrequencyKey;

@interface ObservationFetchService : NSObject

- (id) init;

- (void) start;
- (void) stop;

@end
