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
        case TimeFilterLastHour:
            return @"Last Hour";
        case TimeFilterLast6Hours:
            return @"Last 6 Hours";
        case TimeFilterLast12Hours:
            return @"Last 12 Hours";
        case TimeFilterLast24Hours:
            return @"Last 24 Hours";
        case TimeFilterToday:
            return @"Today";
        default:
            return @"";
    }
}

+ (UIAlertController *) createFilterActionSheet {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Filter"
                                                                   message:@"Filter observations and people by time"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int type = TimeFilterAll; type <= TimeFilterToday; ++type) {
        UIAlertAction *action = [self createAlertAction:type];
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    return alert;
}

+ (UIAlertAction *) createAlertAction:(TimeFilterType) timeFilter {
    TimeFilterType currentFilter = [TimeFilter getTimeFilter];

    UIAlertAction *action = [UIAlertAction actionWithTitle:[TimeFilter timeFilterStringForType:timeFilter] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TimeFilter setTimeFilter:timeFilter];
    }];
    action.enabled = currentFilter != timeFilter;

    return action;
}


@end
