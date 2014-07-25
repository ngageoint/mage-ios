//
//  TimeTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 5/2/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ValueTableViewCell.h"

@implementation ValueTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
