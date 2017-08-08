//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextFieldTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface ObservationEditTextFieldTableViewCell ()
@property (strong, nonatomic) NSString *value;
@end

@implementation ObservationEditTextFieldTableViewCell

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
        
    if (valid) {
        self.textField.layer.borderColor = nil;
    } else {
        self.textField.layer.cornerRadius = 4.0f;
        self.textField.layer.masksToBounds = YES;
        self.textField.layer.borderColor = [[UIColor redColor] CGColor];
        self.textField.layer.borderWidth = 1.0f;
    }
};


@end
