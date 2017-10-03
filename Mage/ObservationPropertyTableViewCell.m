//
//  ObservationPropertyTableViewCell.m
//  Mage
//
//

#import "ObservationPropertyTableViewCell.h"

@implementation ObservationPropertyTableViewCell

- (void) populateCellWithKey:(id)key andValue:(id)value {
    self.valueTextView.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", [self.fieldDefinition valueForKey:@"title"]];
    [self.valueTextView setSecureTextEntry:YES];
}

@end
