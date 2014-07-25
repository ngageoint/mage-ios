//
//  ObservationDateTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationDateTableViewCell.h"
#import <NSDate+DateTools.h>

@interface ObservationDateTableViewCell()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@end

@implementation ObservationDateTableViewCell

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

- (void) populateCellWithKey:(id) key andValue:(id) value {
    NSDate* output = [self.dateParseFormatter dateFromString:value];
    
    self.valueTextView.text = [NSString stringWithFormat:@"%@", [self.dateDisplayFormatter stringFromDate:output]];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
