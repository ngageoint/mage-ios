//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextFieldTableViewCell.h"
#import "Theme+UIResponder.h"
#import <SkyFloatingLabelTextField/SkyFloatingLabelTextField-Swift.h>

@interface ObservationEditTextFieldTableViewCell ()
@property (strong, nonatomic) NSString *value;
@end

@implementation ObservationEditTextFieldTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.keyLabel.textColor = [UIColor primaryText];
    self.textField.textColor = [UIColor primaryText];
    self.textField.backgroundColor = [UIColor dialog];
    
//    CALayer *border = [CALayer layer];
//    CGFloat borderWidth = 1.0;
//    border.frame = CGRectMake(0, self.textField.frame.size.height - borderWidth, self.textField.frame.size.width, self.textField.frame.size.height);
//    border.borderWidth = borderWidth;
//    [self.textField.layer addSublayer:border];
//    self.textField.layer.masksToBounds = YES;
    
    if (self.fieldValueValid) {
//        border.borderColor = [UIColor brand].CGColor;
        self.requiredIndicator.textColor = [UIColor primaryText];
    } else {
//        border.borderColor = [UIColor redColor].CGColor;
        self.requiredIndicator.textColor = [UIColor redColor];
    }
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, barButton, nil];
    self.textField.inputAccessoryView = toolbar;
    [self.textField setDelegate: self];
}


- (void) populateCellWithFormField: (id) field andValue: (id) value {
    [self.textField setText:value];    
    self.value = self.textField.text;
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (void) selectRow {
    [self.textField becomeFirstResponder];
}

- (void) cancelButtonPressed {
    self.textField.text = self.value;
    [self.textField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (![self.value isEqualToString:self.textField.text]) {
        self.value = self.textField.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:self.value reloadCell:NO];
        }
    }
}

- (BOOL) isEmpty {
    return [self.textField.text length] == 0;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    [self themeDidChange:TheCurrentTheme];
};


@end
