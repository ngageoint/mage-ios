//
//  ObservationCheckboxViewTableViewCell.m
//  MAGE
//
//

#import "ObservationCheckboxViewTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationCheckboxViewTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.checkboxSwitch.onTintColor = [UIColor themedButton];
    self.keyLabel.textColor = [UIColor primaryText];
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    [self.checkboxSwitch setOn:[value boolValue]];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
