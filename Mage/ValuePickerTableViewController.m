//
//  ValuePickerTableViewController.m
//  Mage
//
//

#import "ValuePickerTableViewController.h"
#import "ValueTableViewCell.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface ValuePickerTableViewController ()

@end

@implementation ValuePickerTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
}

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
    [self registerForThemeChanges];
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:self.section];
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
