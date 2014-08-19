//
//  ValuePickerTableViewController.m
//  Mage
//
//  Created by Dan Barela on 5/2/14.
//

#import "ValuePickerTableViewController.h"
#import "ValueTableViewCell.h"

@interface ValuePickerTableViewController ()

@end

@implementation ValuePickerTableViewController

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
    return _values.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _section;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"valueTableCell";
    ValueTableViewCell *cell = [tableView
                              dequeueReusableCellWithIdentifier:CellIdentifier
                              forIndexPath:indexPath];
    
    long row = [indexPath row];
    cell.valueLabel.text = _labels[row];
    cell.preferenceValue = _values[row];
    
    if ([_values[row] unsignedLongLongValue] == [_selected unsignedLongLongValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long row = [indexPath row];
    _selected = _values[row];
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    ValueTableViewCell *cell = (ValueTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [defaults setObject: cell.preferenceValue forKey:_preferenceKey];
    [defaults synchronize];
    
    [tableView reloadData];
    
}

@end
