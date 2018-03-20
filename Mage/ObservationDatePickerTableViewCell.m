//
//  ObservationDatePickerTableViewCell.m
//  Mage
//
//

@import DateTools;
@import HexColors;

#import "ObservationDatePickerTableViewCell.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"

@interface ObservationDatePickerTableViewCell ()
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) NSDate *date;
@property (assign, nonatomic) BOOL canceled;
@property (strong, nonatomic) NSDate *value;
@end

@implementation ObservationDatePickerTableViewCell

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
    self.textField.iconText = @"\U0000f073";
    self.textField.iconColor = [UIColor secondaryText];
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    self.date = nil;
    self.canceled = NO;
    
    self.datePicker = [[UIDatePicker alloc] init];
    if (![NSDate isDisplayGMT]) {
        self.datePicker.timeZone = [NSTimeZone localTimeZone];
    } else {
        self.datePicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    
    if ([value length] > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        // Always use this locale when parsing fixed format date strings
        NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [formatter setLocale:posix];
        self.value = [formatter dateFromString:(NSString *) value];
        self.datePicker.date = self.value;
    } else {
        self.value = nil;
        self.datePicker.date = [[NSDate alloc] init];
    }
    [self setTextFieldValue];
    
    [self.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.textField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UILabel *timeZoneLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    timeZoneLabel.text = [self.datePicker.timeZone name];
    [timeZoneLabel sizeToFit];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, [[UIBarButtonItem alloc] initWithCustomView:timeZoneLabel], flexSpace, doneBarButton, nil];
    
    self.textField.inputView = self.datePicker;
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.inputAccessoryView = toolbar;
    [self.textField setDelegate:self];

    [self registerForThemeChanges];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
    }];
    
    return [super canPerformAction:action withSender:sender];
}

- (void) setTextFieldValue {
    if (self.value) {
        [self.textField setText:[self.value formattedDisplayDate]];
    } else {
        [self.textField setText:nil];
    }
}

- (BOOL) isEmpty {
    return [self.textField.text length] == 0;
}

- (void) selectRow {
    [self.textField becomeFirstResponder];
}

- (void) cancelButtonPressed {
    self.date = self.value;
    [self setTextFieldValue];
    [self.textField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.textField resignFirstResponder];
}

- (void) dateChanged:(id) sender {
    self.date = self.datePicker.date;
    self.textField.text = [self.date formattedDisplayDate];
}

- (BOOL) textFieldShouldClear:(UITextField *)textField {
    self.date = nil;
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    [self dateChanged:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (![self.value isEqualToDate:self.date]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        // Always use this locale when parsing fixed format date strings
        NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [formatter setLocale:posix];
        
        id value = self.date ? [formatter stringFromDate:self.date] : nil;
        self.value = self.date;

        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:value reloadCell:NO];
        }
    }
    self.datePicker.date = self.date ? self.date : [[NSDate alloc] init];
}

- (BOOL) isValid {
    return [super isValid] && [self isValid: self.value];
}

- (BOOL) isValid: (NSDate *) date {
    
    if (date == nil && [[self.fieldDefinition objectForKey: @"required"] boolValue]) {
        return NO;
    }
    
    return YES;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.textField.errorMessage = nil;
    } else {
        self.textField.errorMessage = self.textField.placeholder;
    }
}



@end
