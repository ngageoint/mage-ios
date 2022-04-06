//
//  ValuePickerTableViewController.m
//  Mage
//

#import "ValuePickerTableViewController.h"

@interface ValuePickerTableViewController()

@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation ValuePickerTableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>)containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selected = [defaults objectForKey:self.preferenceKey];
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
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
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
    cell.textLabel.text = self.labels[indexPath.row];
    
    if ([self.selected isEqual:self.values[indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id value = [self.values objectAtIndex:indexPath.row];
    
    self.selected = self.values[indexPath.row];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:self.preferenceKey];
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
        header.textLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.6];
    }
}

@end
