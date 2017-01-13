//
//  TimeFilter.m
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TimeFilter.h"

@interface TimeFilter ()
@property (strong, nonatomic) NSArray *trackingButton;
@end

@implementation TimeFilter

NSString * const kTimeFilterKey = @"timeFilterKey";


+ (TimeFilterType) getTimeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:kTimeFilterKey];
}

+ (void) setTimeFilter:(TimeFilterType) timeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:timeFilter forKey:kTimeFilterKey];
    [defaults synchronize];
}


+ (NSString *) getTimeFilterString {
    return [TimeFilter timeFilterStringForType:[TimeFilter getTimeFilter]];
}

+ (NSString *) timeFilterStringForType:(TimeFilterType) timeFilterType {
    switch (timeFilterType) {
        case TimeFilterAll:
            return @"All";
        case TimeFilterToday:
            return @"Today";
        case TimeFilterLast24Hours:
            return @"Last 24 Hours";
        case TimeFilterLastWeek:
            return @"Last Week";
        case TimeFilterLastMonth:
            return @"Last Month";
        default:
            return @"";
    }
}

+ (NSPredicate *) getTimePredicateForField:(NSString *) field {
    TimeFilterType timeFilter = [TimeFilter getTimeFilter];
    switch (timeFilter) {
        case TimeFilterToday: {
            NSDate *start = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];
            
            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.day = 1;
            components.second = -1;
            NSDate *end = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:NSCalendarMatchStrictly];
            
            return [NSPredicate predicateWithFormat:@"%K >= %@ && %K <= %@", field, start, field, end];
        }
        case TimeFilterLast24Hours: {
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:-24*60*60];
            return [NSPredicate predicateWithFormat:@"%K>= %@", field, date];
        }
        case TimeFilterLastWeek: {
            NSDate *start = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];
            NSDate *date = [start dateByAddingTimeInterval:-7*24*60*60];
            return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
        }
        case TimeFilterLastMonth: {
            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.month = -1;
            NSDate *date = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]] options:NSCalendarMatchStrictly];
            
            return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
        }
        default: {
            return nil;
        }
    }
}

@end
