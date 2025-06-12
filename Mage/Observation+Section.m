//
//  Observation+Section.m
//  MAGE
//
//  Created by Dan Barela on 4/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Observation+Section.h"
#import "NSDate+display.h"
#import "MAGE-Swift.h"

@implementation Observation (Section)

- (NSString *) dateSection {
    return [self.timestamp formattedDisplayDateWithDateStyle:NSDateFormatterLongStyle andTimeStyle:NSDateFormatterNoStyle];
}

- (NSString *) dirtySection {
    if (self.dirty) {
        return @"Observations Awaiting Sync";
    } else {
        return [self.timestamp formattedDisplayDateWithDateStyle:NSDateFormatterLongStyle andTimeStyle:NSDateFormatterNoStyle];
    }
}

@end
