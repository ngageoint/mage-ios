//
//  DataFetchSettingsTableViewController.m
//  Mage
//
//

#import "AdvancedWiFiTableViewController.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"
#import "ValuePickerTableViewController.h"
#import "DataConnectionUtilities.h"

@interface AdvancedWiFiTableViewController ()

@property (assign, nonatomic) NSNumber *wifiNetworkRestrictionType;
@property (strong, nonatomic) NSMutableArray *wifiWhitelist;
@property (strong, nonatomic) NSMutableArray *wifiBlacklist;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation AdvancedWiFiTableViewController

static NSInteger RESTRICTION_TYPE_SECTION = 0;
static NSInteger RESTRICTIONS_SECTION = 1;

static NSInteger NO_RESTRICTIONS_CELL_ROW = 0;
static NSInteger ONLY_THESE_WIFI_NETWORKS_CELL_ROW = 1;
static NSInteger NOT_THESE_WIFI_NETWORKS_CELL_ROW = 2;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = @"Advanced WiFi";
    self.scheme = containerScheme;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.wifiNetworkRestrictionType = [defaults objectForKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [defaults objectForKey:@"wifiWhitelist"];
    NSArray *blacklist = [defaults objectForKey:@"wifiBlacklist"];
    if (blacklist == nil) {
        self.wifiBlacklist = [[NSMutableArray alloc] init];
    } else {
        self.wifiBlacklist = [blacklist mutableCopy];
    }
    if (whitelist == nil) {
        self.wifiWhitelist = [[NSMutableArray alloc] init];
    } else {
        self.wifiWhitelist = [whitelist mutableCopy];
    }

    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self applyThemeWithContainerScheme:self.scheme];
}

#pragma mark - Table view data source


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row != 0) {
        __weak typeof(self) weakSelf = self;

        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Remove" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([weakSelf.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
                [weakSelf.wifiWhitelist removeObjectAtIndex:indexPath.row - 1];
                [defaults setObject:weakSelf.wifiBlacklist forKey:@"wifiWihtelist"];
                
            } else if ([weakSelf.wifiNetworkRestrictionType longValue] == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
                [weakSelf.wifiBlacklist removeObjectAtIndex:indexPath.row - 1];
                [defaults setObject:weakSelf.wifiBlacklist forKey:@"wifiBlacklist"];
            }
            [defaults synchronize];
            [weakSelf.tableView reloadData];
        }];

        UISwipeActionsConfiguration *swipeActions = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
        swipeActions.performsFirstActionWithFullSwipe = YES;
        return swipeActions;
    }
    return nil;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == RESTRICTION_TYPE_SECTION) return 3;
    if ([self.wifiNetworkRestrictionType longValue] == WIFIRestrictionTypeNotTheseWifiNetworks) {
        return 1 + [self.wifiBlacklist count];
    }
    if ([self.wifiNetworkRestrictionType longValue] == WIFIRestrictionTypeOnlyTheseWifiNetworks) {
        return 1 + [self.wifiWhitelist count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RESTRICTION_TYPE_SECTION) {
        NSString * cellText;
        if (indexPath.row == NO_RESTRICTIONS_CELL_ROW) {
            cellText = @"No Restrictions";
        } else if (indexPath.row == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
            cellText = @"Allowed WiFi Networks Only";
        } else if (indexPath.row == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
            cellText = @"Exclude These WiFi Networks";
        }
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = cellText;
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        cell.accessoryType = [self.wifiNetworkRestrictionType longValue] == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        return cell;
    } else if (indexPath.section == RESTRICTIONS_SECTION) {
        if ([self.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
            if (indexPath.row == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Add a WiFi SSID";
                cell.textLabel.textColor = self.scheme.colorScheme.primaryColor;
                cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
                return cell;
            } else {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = [self.wifiWhitelist objectAtIndex:indexPath.row - 1];
                cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
                cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
                return cell;
            }
        } else if ([self.wifiNetworkRestrictionType longValue] == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
            if (indexPath.row == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Add a WiFi SSID";
                cell.textLabel.textColor = self.scheme.colorScheme.primaryColor;
                cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
                return cell;
            } else {
               UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
               cell.textLabel.text = [self.wifiBlacklist objectAtIndex:indexPath.row - 1];
               cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
               cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
               return cell;
           }
        }
    }
    return nil;
}

- (void) presentAddSSIDAlert: (BOOL) whitelist {
    NSString *message = [NSString stringWithFormat:@"Add a WiFi SSID to the list of networks to %@", whitelist ? @"whitelist." : @"blacklist."];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add a WiFi SSID" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        // only actually add it if it doesn't already exist in the list
        NSString *currentSSID = [DataConnectionUtilities getCurrentWifiSsid];
        textField.placeholder = @"WiFi SSID";
        textField.secureTextEntry = NO;
        textField.text = currentSSID;
    }];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *ssid = [[alertController textFields][0] text];
        NSLog(@"SSID %@", ssid);
        if (whitelist) {
            if (![weakSelf.wifiWhitelist containsObject:ssid]) {
                [weakSelf.wifiWhitelist addObject:ssid];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:weakSelf.wifiWhitelist forKey:@"wifiWhitelist"];
                [defaults synchronize];
            }
        } else {
            if (![weakSelf.wifiBlacklist containsObject:ssid]) {
                [weakSelf.wifiBlacklist addObject:ssid];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:weakSelf.wifiBlacklist forKey:@"wifiBlacklist"];
                [defaults synchronize];
            }
        }
        [weakSelf.tableView reloadData];
    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RESTRICTION_TYPE_SECTION) {
        self.wifiNetworkRestrictionType = [NSNumber numberWithLong:indexPath.row];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: self.wifiNetworkRestrictionType forKey:@"wifiNetworkRestrictionType"];
        [defaults synchronize];
    } else if (indexPath.section == RESTRICTIONS_SECTION) {
        if (indexPath.row == 0) {
            [self presentAddSSIDAlert: [self.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == RESTRICTION_TYPE_SECTION) {
        return @"WiFi Networks";
    }
    if (section == RESTRICTIONS_SECTION) {
        if ([self.wifiNetworkRestrictionType longValue] == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
            return @"Exclude These WiFi Networks:";
        } else if ([self.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
            return @"Only Use These WiFi Networks:";
        }
        return @"Any WiFi Network Will Be Used";
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.6];
    }
}

@end
