//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextFieldTableViewCell.h"
#import "Theme+UIResponder.h"
@import HexColors;

@interface ObservationEditTextFieldTableViewCell ()
@property (strong, nonatomic) NSString *value;
@end

@implementation ObservationEditTextFieldTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    
    self.textField.textColor = [UIColor primaryText];
    self.textField.selectedLineColor = [UIColor brand];
    self.textField.selectedTitleColor = [UIColor brand];
    self.textField.placeholderColor = [UIColor secondaryText];
    self.textField.lineColor = [UIColor secondaryText];
    self.textField.titleColor = [UIColor secondaryText];
    self.textField.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    self.textField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.textField.iconText = @"\U0000f044";
    if (self.fieldDefinition && [[self.fieldDefinition objectForKey:@"type"] isEqualToString:@"password"] ) {
        self.textField.iconText = @"\U0000f084";
    } else if (self.fieldDefinition && [[self.fieldDefinition objectForKey:@"type"] isEqualToString:@"email"] ) {
        self.textField.iconText = @"\U0000f0e0";
    }
    self.textField.iconColor = [UIColor secondaryText];
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
    
    self.textField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
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
        self.textField.errorMessage = nil;
    } else {
        self.textField.errorMessage = self.textField.placeholder;
    }
};


@end
