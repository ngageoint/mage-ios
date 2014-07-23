//
//  ObservationDateTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationDateTableViewCell.h"

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
    self.valueTextView.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
