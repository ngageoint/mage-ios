//
//  ObservationPropertyTableViewCell.m
//  Mage
//
//

#import "ObservationPropertyTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationPropertyTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.valueLabel.textColor = [UIColor primaryText];
    self.keyLabel.textColor = [UIColor secondaryText];
    self.valueTextView.textColor = [UIColor primaryText];
    self.valueTextView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor flatButton]};
}

- (void) populateCellWithKey:(id)key andValue:(id)value {
    [self registerForThemeChanges];
    self.valueTextView.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", [self.fieldDefinition valueForKey:@"title"]];
    [self.valueTextView setSecureTextEntry:YES];
}

@end
