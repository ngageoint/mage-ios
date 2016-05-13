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
    TimeFilterLastHour,
    TimeFilterLast6Hours,
    TimeFilterLast12Hours,
    TimeFilterLast24Hours,
    TimeFilterToday
};

@protocol TimeFilterDelegate <NSObject>

-(void) showFilterActionSheet:(UIViewController *) viewController complete:(void (^) (TimeFilterType timeFilter)) complete;

@end

@interface TimeFilter : NSObject<TimeFilterDelegate>

extern NSString * const kTimeFilterKey;



+ (TimeFilterType) getTimeFilter;
+ (void) setTimeFilter:(TimeFilterType) timeFilter;

+ (NSString *) getTimeFilterString;

@end
