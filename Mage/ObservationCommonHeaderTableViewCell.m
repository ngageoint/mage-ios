//
//  ObservationCommonHeaderTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationCommonHeaderTableViewCell.h"
#import <Server+helper.h>
#import <User.h>
#import <Event+helper.h>

@interface ObservationCommonHeaderTableViewCell ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ObservationCommonHeaderTableViewCell

- (NSDateFormatter *) dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    }
    
    return _dateFormatter;
}

- (void) configureCellForObservation: (Observation *) observation {
    NSString *name = [observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    if (variantField != nil) {
        self.variantFieldLabel.text = [observation.properties objectForKey:variantField];
    } else {
        self.variantFieldLabel.text = @"";
    }
    
    self.userLabel.text = observation.user.name;
    
    self.userLabel.text = [NSString stringWithFormat:@"%@ (%@)", observation.user.name, observation.user.username];
    self.dateLabel.text = [self.dateFormatter stringFromDate:observation.timestamp];
}

@end
