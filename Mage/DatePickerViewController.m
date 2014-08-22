//
//  DatePickerViewController.m
//  Mage
//
//  Created by Dan Barela on 8/21/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@end

@implementation DatePickerViewController

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _datePicker.date = [[self dateParseFormatter] dateFromString:self.value];
    _dateKeyName.text = [_fieldDefinition objectForKey:@"title"];
    [_datePicker addTarget:self action:@selector(pickerDateChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void) pickerDateChanged: (id) sender {
    _value = [[self dateParseFormatter] stringFromDate:_datePicker.date];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
