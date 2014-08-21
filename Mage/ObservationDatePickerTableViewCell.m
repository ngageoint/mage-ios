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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    NSDate *date = [[self dateParseFormatter] dateFromString:[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
    [self.valueLabel setText:[[self dateDisplayFormatter] stringFromDate:date]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

@end
