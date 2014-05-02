//
//  TimePickerTableViewController.m
//  Mage
//
//  Created by Dan Barela on 5/2/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "TimePickerTableViewController.h"
#import "TimeTableViewCell.h"

@interface TimePickerTableViewController ()

@end

@implementation TimePickerTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    _selected = [defaults objectForKey:_preferenceKey];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _times.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"timeTableCell";
    TimeTableViewCell *cell = [tableView
                              dequeueReusableCellWithIdentifier:CellIdentifier
                              forIndexPath:indexPath];
    
    long row = [indexPath row];
    
    cell.timeLabel.text = _times[row];
    cell.preferenceValue = _values[row];
    
    NSLog(@"Selected is %@", _selected);
    NSLog(@"Row: %@", _values[row]);
    NSLog(@"times row: %@", _times[row]);
    
    if ([_values[row] unsignedLongLongValue] == [_selected unsignedLongLongValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSLog(@"the same");
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSLog(@"different");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long row = [indexPath row];
    _selected = _values[row];
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    TimeTableViewCell *cell = (TimeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [defaults setObject: cell.preferenceValue forKey:_preferenceKey];
    [defaults synchronize];
    
    [tableView reloadData];
    
}

@end
