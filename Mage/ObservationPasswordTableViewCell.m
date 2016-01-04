//
//  ObservationPasswordTableViewCell.m
//  Mage
//
//

#import "ObservationPasswordTableViewCell.h"

@implementation ObservationPasswordTableViewCell

- (void) populateCellWithKey:(id) key andValue:(id) value {
    self.passwordField.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
