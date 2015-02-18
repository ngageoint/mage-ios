//
//  ObservationDatePickerTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 8/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationDatePickerTableViewCell.h"

@interface ObservationDatePickerTableViewCell ()

@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@property (strong, nonatomic) UIDatePicker *datePicker;

@end

@implementation ObservationDatePickerTableViewCell

- (NSDateFormatter *) dateDisplayFormatter {
	if (_dateDisplayFormatter == nil) {
		_dateDisplayFormatter = [[NSDateFormatter alloc] init];
		[_dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateDisplayFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateDisplayFormatter;
}

- (NSDateFormatter *) dateParseFormatter {
	if (_dateParseFormatter == nil) {
		_dateParseFormatter = [[NSDateFormatter alloc] init];
		[_dateParseFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateParseFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z"];
        NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateParseFormatter.locale = posix;
	}
	
	return _dateParseFormatter;
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    NSDate *date = [[self dateParseFormatter] dateFromString:[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.date = date;
    [self.valueTextField setText:[[self dateDisplayFormatter] stringFromDate:_datePicker.date]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, doneBarButton, nil];
    self.valueTextField.inputView = _datePicker;
    self.valueTextField.inputAccessoryView = toolbar;
}

- (void) cancelButtonPressed {
    [self.valueTextField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.valueTextField resignFirstResponder];
    NSString *newValue = [[self dateParseFormatter] stringFromDate:_datePicker.date];
    self.valueTextField.text = newValue;
    [self.valueTextField setText:[[self dateDisplayFormatter] stringFromDate:_datePicker.date]];

    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue reloadCell:NO];
    }
}


@end
