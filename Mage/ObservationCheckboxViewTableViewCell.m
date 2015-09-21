//
//  ObservationCheckboxViewTableViewCell.m
//  MAGE
//
//

#import "ObservationCheckboxViewTableViewCell.h"

@implementation ObservationCheckboxViewTableViewCell

- (void) populateCellWithKey:(id) key andValue:(id) value {
    [self.checkboxSwitch setOn:[value boolValue]];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
