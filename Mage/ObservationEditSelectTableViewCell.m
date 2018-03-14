//
//  ObservationPickerTableViewCell.m
//  Mage
//
//

#import "ObservationEditSelectTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationEditSelectTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.keyLabel.textColor = [UIColor primaryText];
    self.valueField.textColor = [UIColor primaryText];
    if (self.fieldValueValid) {
        self.valueField.layer.borderColor = nil;
        self.valueField.layer.borderWidth = 0;
        self.requiredIndicator.textColor = [UIColor primaryText];
    } else {
        self.valueField.layer.cornerRadius = 4.0f;
        self.valueField.layer.masksToBounds = YES;
        self.valueField.layer.borderColor = [[UIColor redColor] CGColor];
        self.valueField.layer.borderWidth = 1.0f;
        self.requiredIndicator.textColor = [UIColor redColor];
    }
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    self.valueField.lineBreakMode = NSLineBreakByWordWrapping;
    self.valueField.numberOfLines = 0;
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    self.value = value;
    
    if ([@"multiselectdropdown" isEqualToString:[self.fieldDefinition objectForKey:@"type"] ]) {
        self.valueField.text = [self.value componentsJoinedByString:@", "];
    } else {
        self.valueField.text = self.value;
    }
    
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (BOOL) isEmpty {
    return [self.valueField.text length] == 0;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    [self themeDidChange:TheCurrentTheme];
};

@end
