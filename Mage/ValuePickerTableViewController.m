//
//  ValuePickerTableViewController.m
//  Mage
//

#import "ValuePickerTableViewController.h"
#import "Theme+UIResponder.h"

@implementation ValuePickerTableViewController

- (void) viewDidLoad {
    [self registerForThemeChanges];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selected = [defaults objectForKey:self.preferenceKey];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.values.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.backgroundColor = [UIColor background];
    
    cell.textLabel.text = self.labels[indexPath.row];
    cell.tag = [self.values[indexPath.row] integerValue];
    
    if ([self.values[indexPath.row] unsignedLongLongValue] == [self.selected unsignedLongLongValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selected = self.values[indexPath.row];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [defaults setObject:[NSNumber numberWithInteger:cell.tag] forKey:self.preferenceKey];
    [defaults synchronize];
    
    [tableView reloadData];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.section;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor brand];
    }
}

@end
