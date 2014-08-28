//
//  DatePickerTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 8/22/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DatePickerTableViewCell.h"

@interface DatePickerTableViewCell ()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@end

@implementation DatePickerTableViewCell

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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [_datePicker addTarget:self action:@selector(pickerDateChanged:) forControlEvents:UIControlEventValueChanged];
        
    }
    return self;
}

- (void)awakeFromNib
{
    [_datePicker addTarget:self action:@selector(pickerDateChanged:) forControlEvents:UIControlEventValueChanged];
    
}

- (CGFloat) getCellHeightForValue:(id)value {
    BOOL boolValue = [value boolValue];
    if (boolValue == NO) {
        return 162.0;
    } else {
        return 0;
    }
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    NSString *dateStr = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    _datePicker.date = [[self dateParseFormatter] dateFromString:dateStr];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) pickerDateChanged: (id) sender {
    NSString *newValue = [[self dateParseFormatter] stringFromDate:_datePicker.date];
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue];
    }

}

@end
