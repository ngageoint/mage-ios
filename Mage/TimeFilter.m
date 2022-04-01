//
//  TimeFilter.m
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TimeFilter.h"
#import "MAGE-Swift.h"

@interface TimeFilter ()
@property (strong, nonatomic) NSArray *trackingButton;
@end

@implementation TimeFilter

+ (TimeFilterType) getObservationTimeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.observationTimeFilterKey;
}

+ (void) setObservationTimeFilter:(TimeFilterType) timeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.observationTimeFilterKey = timeFilter;
    [defaults synchronize];
}

+ (NSString *) getObservationTimeFilterString {
    return [TimeFilter observationTimeFilterStringForType:[TimeFilter getObservationTimeFilter]];
}

+ (TimeUnit) getObservationCustomTimeFilterUnit {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.observationTimeFilterUnitKey;
}

+ (void) setObservationCustomTimeFilterUnit:(TimeUnit) timeUnit {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.observationTimeFilterUnitKey = timeUnit;
    [defaults synchronize];
}

+ (NSInteger) getObservationCustomTimeFilterNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.observationTimeFilterNumberKey;
}

+ (void) setObservationCustomTimeFilterNumber: (NSInteger) timeNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.observationTimeFilterNumberKey = timeNumber;
    [defaults synchronize];
}

+ (TimeFilterType) getLocationTimeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.locationTimeFilter;
}

+ (void) setLocationTimeFilter:(TimeFilterType) timeFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.locationTimeFilter = timeFilter;
    [defaults synchronize];
}

+ (NSString *) getLocationTimeFilterString {
    return [TimeFilter locationTimeFilterStringForType:[TimeFilter getLocationTimeFilter]];
}

+ (TimeUnit) getLocationCustomTimeFilterUnit {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.locationTimeFilterUnit;
}

+ (void) setLocationCustomTimeFilterUnit:(TimeUnit) timeUnit {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.locationTimeFilterUnit = timeUnit;
    [defaults synchronize];
}

+ (NSInteger) getLocationCustomTimeFilterNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.locationTimeFilterNumber;
}

+ (void) setLocationCustomTimeFilterNumber: (NSInteger) timeNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.locationTimeFilterNumber = timeNumber;
    [defaults synchronize];
}

+ (NSString *) timeUnitStringForType:(TimeUnit) timeUnit {
    switch (timeUnit) {
        case Hours:
            return @"Hours";
        case Months:
            return @"Months";
        case Days:
            return @"Days";
    }
    return @"";
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
        case TimeFilterCustom:
            return @"Custom";
        default:
            return @"";
    }
}

+ (NSString *) locationTimeFilterStringForType:(TimeFilterType) timeFilterType {
    switch (timeFilterType) {
        case TimeFilterCustom:
            return [NSString stringWithFormat:@"Last %ld %@", (long)[TimeFilter getLocationCustomTimeFilterNumber], [TimeFilter timeUnitStringForType:[TimeFilter getLocationCustomTimeFilterUnit]]];
        default:
            return [TimeFilter timeFilterStringForType:timeFilterType];
    }
}

+ (NSString *) observationTimeFilterStringForType:(TimeFilterType) timeFilterType {
    switch (timeFilterType) {
        case TimeFilterCustom:
            return [NSString stringWithFormat:@"Last %ld %@", (long)[TimeFilter getObservationCustomTimeFilterNumber], [TimeFilter timeUnitStringForType:[TimeFilter getObservationCustomTimeFilterUnit]]];
        default:
            return [TimeFilter timeFilterStringForType:timeFilterType];
    }
}

+ (NSPredicate *) getLocationTimePredicateForField:(NSString *) field {
    TimeFilterType timeFilter = [TimeFilter getLocationTimeFilter];
    TimeUnit unit = [TimeFilter getLocationCustomTimeFilterUnit];
    switch (timeFilter) {
        case TimeFilterCustom: {
            switch (unit) {
                case Hours: {
                    NSDate *date = [[NSDate date] dateByAddingTimeInterval:-60*60* [TimeFilter getLocationCustomTimeFilterNumber]];
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
                case Days: {
                    NSDate *date = [[NSDate date] dateByAddingTimeInterval:-24*60*60* [TimeFilter getLocationCustomTimeFilterNumber]];
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
                case Months: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.month = -1*[TimeFilter getLocationCustomTimeFilterNumber];
                    NSDate *date = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]] options:NSCalendarMatchStrictly];
                    
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
            }
        }
        default:
            return [TimeFilter getTimePredicateForField:field andTimeFilter:timeFilter];
    }
    return nil;

}

+ (NSPredicate *) getObservationTimePredicateForField:(NSString *) field {
    TimeFilterType timeFilter = [TimeFilter getObservationTimeFilter];
    TimeUnit unit = [TimeFilter getObservationCustomTimeFilterUnit];
    switch (timeFilter) {
        case TimeFilterCustom: {
            switch (unit) {
                case Hours: {
                    NSDate *date = [[NSDate date] dateByAddingTimeInterval:-60*60* [TimeFilter getObservationCustomTimeFilterNumber]];
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
                case Days: {
                    NSDate *date = [[NSDate date] dateByAddingTimeInterval:-24*60*60* [TimeFilter getObservationCustomTimeFilterNumber]];
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
                case Months: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.month = -1*[TimeFilter getObservationCustomTimeFilterNumber];
                    NSDate *date = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]] options:NSCalendarMatchStrictly];
                    
                    return [NSPredicate predicateWithFormat:@"%K >= %@", field, date];
                }
            }
        }
        default:
            return [TimeFilter getTimePredicateForField:field andTimeFilter:timeFilter];
    }
    return nil;
}

+ (NSPredicate *) getTimePredicateForField: (NSString *) field andTimeFilter: (TimeFilterType) timeFilter {
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
        case TimeFilterCustom: {
            // TODO
            return nil;
        }
        default: {
            return nil;
        }
    }
}

@end
