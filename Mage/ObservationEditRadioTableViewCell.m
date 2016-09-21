//
//  ObservationEditRadioTableViewCell.m
//  MAGE
//

#import "ObservationEditRadioTableViewCell.h"

@implementation ObservationEditRadioTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    self.pickerValues = [NSMutableArray array];
    for (id choice in [field objectForKey:@"choices"]) {
        NSString *title = [choice objectForKey:@"title"];
        NSLog(@"title is %@", title);
        
        if (title) {
            [self.pickerValues addObject:title];
        }
    }
    self.picker = [[UIPickerView alloc] init];
    self.picker.delegate = self;
    self.picker.dataSource = self;
    [self.picker reloadAllComponents];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, doneBarButton, nil];
    self.valueTextField.inputView = self.picker;
    self.valueTextField.inputAccessoryView = toolbar;
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    if ([observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]] != nil) {
        [self.valueTextField setText:[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
    }
    
    NSUInteger index = [self.pickerValues indexOfObject:self.valueTextField.text];
    if (index != NSNotFound) {
        [self.picker selectRow:index inComponent:0 animated:NO];
    }
    
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return self.pickerValues.count;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerValues[row];
}

- (void) selectRow {
    [self.valueTextField becomeFirstResponder];
}

- (void) cancelButtonPressed {
    [self.valueTextField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.valueTextField resignFirstResponder];
    
    NSUInteger row = [self.picker selectedRowInComponent:0];
    if (row >= [self.pickerValues count]) return;
    
    NSString *newValue = [self.pickerValues objectAtIndex:row];
    self.valueTextField.text = newValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue reloadCell:NO];
    }
}

- (BOOL) isEmpty {
    return [self.valueTextField.text length] == 0;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.valueTextField.layer.borderColor = nil;
        self.valueTextField.layer.borderWidth = 0.0f;
    } else {
        self.valueTextField.layer.cornerRadius = 4.0f;
        self.valueTextField.layer.masksToBounds = YES;
        self.valueTextField.layer.borderColor = [[UIColor redColor] CGColor];
        self.valueTextField.layer.borderWidth = 1.0f;
    }
};

@end
