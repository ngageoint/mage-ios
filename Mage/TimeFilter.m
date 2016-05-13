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

-(void) showFilterActionSheet:(UIViewController *) viewController complete:(void (^) (TimeFilterType timeFilter)) complete {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Filter"
                                                                   message:@"Filter observations and people by time"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int type = TimeFilterAll; type <= TimeFilterToday; ++type) {
        UIAlertAction *action = [self createAlertAction:type complete:complete];
        [alert addAction:action];
    }
    
//    UIAlertAction *all = [UIAlertAction actionWithTitle:@"All" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterAll);
//    }];
//    all.enabled = currentFilter != TimeFilterAll;
//    [alert addAction:all];
//    
//    UIAlertAction *lastHour = [UIAlertAction actionWithTitle:@"Last Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterLastHour);
//    }];
//    lastHour.enabled = currentFilter != TimeFilterLastHour;
//    [alert addAction:lastHour];
//    
//    UIAlertAction *last6Hours = [UIAlertAction actionWithTitle:@"Last 6 Hours" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterLast6Hours);
//    }];
//    last6Hours.enabled = currentFilter != TimeFilterLast6Hours;
//    [alert addAction:last6Hours];
//    
//    UIAlertAction *last12Hours = [UIAlertAction actionWithTitle:@"Last 12 Hours" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterLast12Hours);
//    }];
//    last12Hours.enabled = currentFilter != TimeFilterLast12Hours;
//    [alert addAction:last12Hours];
//    
//    UIAlertAction *last24Hours = [UIAlertAction actionWithTitle:@"Last 24 Hours" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterLast24Hours);
//    }];
//    last24Hours.enabled = currentFilter != TimeFilterLast24Hours;
//    [alert addAction:last24Hours];
//    
//    UIAlertAction *today = [UIAlertAction actionWithTitle:@"Today" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        complete(TimeFilterLast24Hours);
//    }];
//    today.enabled = currentFilter != TimeFilterToday;
//    [alert addAction:today];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction *) createAlertAction:(TimeFilterType) timeFilter complete:(void (^) (TimeFilterType timeFilter)) complete {
    TimeFilterType currentFilter = [TimeFilter getTimeFilter];

    UIAlertAction *action = [UIAlertAction actionWithTitle:[TimeFilter timeFilterStringForType:timeFilter] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        complete(timeFilter);
    }];
    action.enabled = currentFilter != timeFilter;

    return action;
}


@end
