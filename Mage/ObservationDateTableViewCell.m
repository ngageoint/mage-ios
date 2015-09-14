//
//  ObservationDateTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationDateTableViewCell.h"
#import "NSDate+Iso8601.h"
#import "NSDate+display.h"

@interface ObservationDateTableViewCell()
@end

@implementation ObservationDateTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    NSDate* date = [NSDate dateFromIso8601String:value];
    
    self.valueTextView.text = [date formattedDisplayDate];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
