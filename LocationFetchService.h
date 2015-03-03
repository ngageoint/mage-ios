//
//  LocationFetchService.h
//  mage-ios-sdk
//
//  Created by William Newman on 8/14/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const kLocationFetchFrequencyKey;

@interface LocationFetchService : NSObject

+ (instancetype) singleton;
- (void) start;
- (void) stop;

@end
