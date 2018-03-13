//
//  ObservationPasswordTableViewCell.m
//  Mage
//
//

#import "ObservationPasswordTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationPasswordTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.passwordField.textColor = [UIColor primaryText];
    self.keyLabel.textColor = [UIColor secondaryText];
    self.backgroundColor = [UIColor dialog];
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    self.passwordField.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
