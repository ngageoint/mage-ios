//
//  ObservationPickerTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 8/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationPickerTableViewCell.h"

@implementation ObservationPickerTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    self.pickerValues = [NSMutableArray array];
    for (id choice in [field objectForKey:@"choices"]) {
        NSLog(@"title is %@", [choice objectForKey:@"title"]);
        [self.pickerValues addObject:[choice objectForKey:@"title"]];
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
    } else {
        [self.valueTextField setText:[field objectForKey:@"value"]];
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

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.pickerValues[row];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) cancelButtonPressed {
    [self.valueTextField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.valueTextField resignFirstResponder];
    NSUInteger row = [self.picker selectedRowInComponent:0];
    NSString *newValue = [self.pickerValues objectAtIndex:row];
    self.valueTextField.text = newValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue reloadCell:NO];
    }
}



@end
