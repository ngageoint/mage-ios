//
//  TimeTableViewCell.m
//  Mage
//
//

#import "ValueTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ValueTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.valueLabel.textColor = [UIColor primaryText];
    self.backgroundColor = [UIColor background];
    self.tintColor = [UIColor flatButton];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

@end
