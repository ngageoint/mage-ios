//
//  ObservationTextAreaTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/24/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationTextAreaTableViewCell.h"

@implementation ObservationTextAreaTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGFloat) getCellHeightForValue:(id)value {
    UIFont *cellFont = self.valueTextView.font;
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    CGSize labelSize = [value sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    [self.valueTextView setFrame:CGRectMake(self.valueTextView.frame.origin.x, self.valueTextView.frame.origin.y, labelSize.width, labelSize.height)];
    return 45 + labelSize.height;
}

@end
