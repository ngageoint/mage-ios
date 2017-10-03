//
//  ObservationPickerTableViewCell.m
//  Mage
//
//

#import "ObservationEditSelectTableViewCell.h"

@implementation ObservationEditSelectTableViewCell

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
    
    if (valid) {
        self.valueField.layer.borderColor = nil;
        self.valueField.layer.borderWidth = 0;
    } else {
        // TODO make this work for the label, used to be uitextfield, it now a uilabel
        self.valueField.layer.cornerRadius = 4.0f;
        self.valueField.layer.masksToBounds = YES;
        self.valueField.layer.borderColor = [[UIColor redColor] CGColor];
        self.valueField.layer.borderWidth = 1.0f;
    }
};

@end
