//
//  ObservationEditTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@implementation ObservationEditTableViewCell

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

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    [self.keyLabel setText:[field objectForKey:@"title"]];
    self.valueTextField.text = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
}

- (CGFloat) getCellHeightForValue: (id) value {
    return self.bounds.size.height;
}

- (void) selectRow {
}

@end
