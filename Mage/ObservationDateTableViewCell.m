//
//  ObservationDateTableViewCell.m
//  Mage
//
//

#import "ObservationDateTableViewCell.h"
#import "NSDate+Iso8601.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"

@interface ObservationDateTableViewCell()
@end

@implementation ObservationDateTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.valueTextView.textColor = [UIColor primaryText];
    self.keyLabel.textColor = [UIColor secondaryText];
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    NSDate* date = [NSDate dateFromIso8601String:value];
    
    self.valueTextView.text = [date formattedDisplayDate];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
    [self registerForThemeChanges];
}

@end
