//
//  TimeFilter.h
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TimeFilterType) {
    TimeFilterAll,
    TimeFilterToday,
    TimeFilterLast24Hours,
    TimeFilterLastWeek,
    TimeFilterLastMonth,
    TimeFilterCustom
};

typedef NS_ENUM(NSUInteger, TimeUnit) {
    Hours,
    Days,
    Months
};

@interface TimeFilter : NSObject

+ (TimeFilterType) getObservationTimeFilter;
+ (void) setObservationTimeFilter:(TimeFilterType) timeFilter;

+ (TimeUnit) getObservationCustomTimeFilterUnit;
+ (void) setObservationCustomTimeFilterUnit:(TimeUnit) timeUnit;

+ (NSInteger) getObservationCustomTimeFilterNumber;
+ (void) setObservationCustomTimeFilterNumber: (NSInteger) timeNumber;

+ (NSString *) getObservationTimeFilterString;

+ (NSPredicate *) getObservationTimePredicateForField:(NSString *) timeField;

+ (TimeFilterType) getLocationTimeFilter;
+ (void) setLocationTimeFilter:(TimeFilterType) timeFilter;

+ (TimeUnit) getLocationCustomTimeFilterUnit;
+ (void) setLocationCustomTimeFilterUnit:(TimeUnit) timeUnit;

+ (NSInteger) getLocationCustomTimeFilterNumber;
+ (void) setLocationCustomTimeFilterNumber: (NSInteger) timeNumber;

+ (NSString *) getLocationTimeFilterString;

+ (NSPredicate *) getLocationTimePredicateForField:(NSString *) timeField;

@end
