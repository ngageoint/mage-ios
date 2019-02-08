//
//  ObservationCheckboxTableViewCell.m
//  MAGE
//
//

#import "ObservationCheckboxTableViewCell.h"
#import "Theme+UIResponder.h"

@import HexColors;

@implementation ObservationCheckboxTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor background];
    if (self.fieldValueValid) {
        self.keyLabel.textColor = [UIColor secondaryText];
    } else {
        self.keyLabel.textColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    }
    self.keyLabel.textColor = [UIColor secondaryText];
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    
    if (value != nil) {
        [self.checkboxSwitch setOn:[value boolValue]];
        [self.delegate observationField:self.fieldDefinition valueChangedTo:value reloadCell:NO];
    } else {
        [self.checkboxSwitch setOn:NO];
    }
    
    NSString *text = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
    self.keyLabel.text = [text uppercaseString];
    
    [self.checkboxSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchValueChanged:(UISwitch *) theSwitch {
    [self.delegate observationField:self.fieldDefinition valueChangedTo:[NSNumber numberWithBool:theSwitch.on] reloadCell:NO];
}

- (CGFloat) getCellHeightForValue: (id) value {
    return self.bounds.size.height;
}

- (void) selectRow {
    [self.checkboxSwitch setOn:!self.checkboxSwitch.isOn];
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];

    [self themeDidChange:TheCurrentTheme];
}

@end
