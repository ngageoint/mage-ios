//
//  ObservationDatePickerTableViewCell.m
//  Mage
//
//

#import "ObservationDatePickerTableViewCell.h"
#import "NSDate+iso8601.h"
#import "NSDate+display.h"

@interface ObservationDatePickerTableViewCell ()
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) NSDate *date;
@property (assign, nonatomic) BOOL canceled;
@property (strong, nonatomic) NSDate *value;
@end

@implementation ObservationDatePickerTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    self.date = nil;
    self.canceled = NO;
    
    self.datePicker = [[UIDatePicker alloc] init];
    if (![NSDate isDisplayGMT]) {
        self.datePicker.timeZone = [NSTimeZone localTimeZone];
    } else {
        self.datePicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    
    if ([[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]] length] > 0) {
        self.value = [NSDate dateFromIso8601String: [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
        self.datePicker.date = self.value;
    } else {
        self.value = nil;
        self.datePicker.date = [[NSDate alloc] init];
    }
    [self setTextFieldValue];
    
    [self.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    [self.keyLabel setText:[field objectForKey:@"title"]];
    
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

    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
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
        id value = self.date ? [self.date iso8601String] : nil;

        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:value reloadCell:NO];
        }
    }
    self.datePicker.date = self.date ? self.date : [[NSDate alloc] init];
    self.value = self.date;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.textField.layer.borderColor = nil;
        self.textField.layer.borderWidth = 0.0f;
    } else {
        self.textField.layer.cornerRadius = 4.0f;
        self.textField.layer.masksToBounds = YES;
        self.textField.layer.borderColor = [[UIColor redColor] CGColor];
        self.textField.layer.borderWidth = 1.0f;
    }
};



@end
