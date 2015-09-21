//
//  ObservationPasswordTableViewCell.m
//  Mage
//
//

#import "ObservationPasswordTableViewCell.h"

@implementation ObservationPasswordTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    self.passwordField.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
