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
@end

@implementation ObservationDatePickerTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    NSDate *date = nil;
    NSString *timestamp = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    if ([timestamp length] > 0) {
        date = [NSDate dateFromIso8601String:timestamp];
    } else {
        date = [[NSDate alloc] init];
        [self.delegate observationField:field valueChangedTo:[date iso8601String] reloadCell:NO];
    }
    
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.date = date;
    [self.valueTextField setText:[_datePicker.date formattedDisplayDate]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, doneBarButton, nil];
    self.valueTextField.inputView = self.datePicker;
    self.valueTextField.inputAccessoryView = toolbar;
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (void) cancelButtonPressed {
    [self.valueTextField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.valueTextField resignFirstResponder];
    NSString *newValue = [_datePicker.date formattedDisplayDate];
    self.valueTextField.text = newValue;

    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue reloadCell:NO];
    }
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
};



@end
