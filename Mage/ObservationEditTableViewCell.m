//
//  ObservationEditTableViewCell.m
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@implementation ObservationEditTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    [self.keyLabel setText:[field objectForKey:@"title"]];
    self.valueTextField.text = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (CGFloat) getCellHeightForValue: (id) value {
    return self.bounds.size.height;
}

- (void) selectRow {
}

@end
