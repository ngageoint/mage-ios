//
//  ObservationPickerTableViewCell.m
//  Mage
//
//

#import "ObservationEditSelectTableViewCell.h"
#import "Theme+UIResponder.h"

@import HexColors;

@implementation ObservationEditSelectTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];

    self.labelField.textColor = [UIColor primaryText];

    self.valueField.textColor = [UIColor primaryText];
    self.valueField.selectedLineColor = [UIColor brand];
    self.valueField.selectedTitleColor = [UIColor brand];
    self.valueField.placeholderColor = [UIColor secondaryText];
    self.valueField.lineColor = [UIColor secondaryText];
    self.valueField.titleColor = [UIColor secondaryText];
    self.valueField.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    self.valueField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.valueField.iconText = @"\U0000f0d7";
    if (self.fieldDefinition && [@"radio" isEqualToString:[self.fieldDefinition objectForKey:@"type"] ]) {
        self.valueField.iconText = @"\U0000f192";
    }
    self.valueField.iconColor = [UIColor secondaryText];
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    self.labelField.lineBreakMode = NSLineBreakByWordWrapping;
    self.labelField.numberOfLines = 0;
    
    self.value = value;
    
    if ([@"multiselectdropdown" isEqualToString:[self.fieldDefinition objectForKey:@"type"] ]) {
        if (!self.value || ((NSArray *)self.value).count == 0) {
            self.valueField.text = nil;
        } else {
            self.valueField.text = @" ";
        }
        self.labelField.text = [self.value componentsJoinedByString:@", "];
    } else {
        if (!self.value) {
            self.valueField.text = nil;
        } else {
            self.valueField.text = @" ";
        }
        self.labelField.text = self.value;
    }
    
    self.valueField.errorMessage = nil;
    self.valueField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
}

- (BOOL) isEmpty {
    return [self.labelField.text length] == 0;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.valueField.errorMessage = nil;
    } else {
        self.valueField.errorMessage = self.valueField.placeholder;
    }
};

@end
