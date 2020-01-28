//
//  DataFetchSettingsTableViewController.m
//  Mage
//
//

#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "AdvancedWiFiTableViewController.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"
#import "ValuePickerTableViewController.h"

@interface AdvancedWiFiTableViewController ()

@property (assign, nonatomic) NSNumber *wifiNetworkRestrictionType;
@property (strong, nonatomic) NSMutableArray *wifiWhitelist;
@property (strong, nonatomic) NSMutableArray *wifiBlacklist;

@end

typedef enum {
    ConnectionTypeUnknown,
    ConnectionTypeNone,
    ConnectionTypeCell,
    ConnectionTypeWiFi
} ConnectionType;


@implementation AdvancedWiFiTableViewController

static NSInteger RESTRICTION_TYPE_SECTION = 0;
static NSInteger RESTRICTIONS_SECTION = 1;

static NSInteger NO_RESTRICTIONS_CELL_ROW = 0;
static NSInteger ONLY_THESE_WIFI_NETWORKS_CELL_ROW = 1;
static NSInteger NOT_THESE_WIFI_NETWORKS_CELL_ROW = 2;

- (instancetype) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = @"Advanced WiFi";
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.wifiNetworkRestrictionType = [defaults objectForKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [defaults objectForKey:@"wifiWhitelist"];
    NSArray *blacklist = [defaults objectForKey:@"wifiBlacklist"];
    self.wifiWhitelist = [defaults objectForKey:@"wifiWhitelist"];
    self.wifiBlacklist = [defaults objectForKey:@"wifiBlacklist"];
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

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self registerForThemeChanges];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == RESTRICTION_TYPE_SECTION) return 3;
    if ([self.wifiNetworkRestrictionType longValue] == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
        return 1 + [self.wifiBlacklist count];
    }
    if ([self.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
        return 1 + [self.wifiWhitelist count];
    }
    return 0;
}

+ (ConnectionType)connectionType
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success) {
        return ConnectionTypeUnknown;
    }
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);

    if (!isNetworkReachable) {
        return ConnectionTypeNone;
    } else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        //connection type
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        NSDictionary *carrier = [netinfo serviceSubscriberCellularProviders];
        NSDictionary *radio = [netinfo serviceCurrentRadioAccessTechnology];
        
        NSLog(@"Carrier %@", carrier);
        NSLog(@"Radio %@", radio);
        
        return ConnectionTypeCell;
    } else {
        return ConnectionTypeWiFi;
    }
}

+ (NSString *) getCurrentWifi {
    NSString *wifiName;
    ConnectionType type = [AdvancedWiFiTableViewController connectionType];
    if (type == ConnectionTypeWiFi) {
        CFArrayRef interfaces = CNCopySupportedInterfaces();
        if (interfaces) {
            CFIndex count = CFArrayGetCount(interfaces);
            for (int i = 0; i < count; i++) {
                CFStringRef interface = (CFStringRef)CFArrayGetValueAtIndex(interfaces, i);
                NSLog(@"Interface %@", interface);
                NSDictionary *dictionary = (__bridge NSDictionary*)CNCopyCurrentNetworkInfo(interface);
                NSLog(@"Dictionary %@", dictionary);
                // if dictionary is nil then there is no wifi
                if (dictionary) {
                    wifiName = [NSString stringWithFormat:@"%@",[dictionary objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID]];
                }
            }
            CFRelease(interfaces);
        }
    }
    return wifiName;
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
        cell.textLabel.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        cell.accessoryType = [self.wifiNetworkRestrictionType longValue] == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        return cell;
    } else if (indexPath.section == RESTRICTIONS_SECTION) {
        if ([self.wifiNetworkRestrictionType longValue] == ONLY_THESE_WIFI_NETWORKS_CELL_ROW) {
            if (indexPath.row == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Add a WiFi SSID";
                cell.textLabel.textColor = [UIColor brand];
                cell.backgroundColor = [UIColor background];
                return cell;
            } else {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = [self.wifiWhitelist objectAtIndex:indexPath.row - 1];
                cell.textLabel.textColor = [UIColor primaryText];
                cell.backgroundColor = [UIColor background];
                return cell;
            }
        } else if ([self.wifiNetworkRestrictionType longValue] == NOT_THESE_WIFI_NETWORKS_CELL_ROW) {
            if (indexPath.row == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Add a WiFi SSID";
                cell.textLabel.textColor = [UIColor brand];
                cell.backgroundColor = [UIColor background];
                return cell;
            } else {
               UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
               cell.textLabel.text = [self.wifiWhitelist objectAtIndex:indexPath.row - 1];
               cell.textLabel.textColor = [UIColor primaryText];
               cell.backgroundColor = [UIColor background];
               return cell;
           }
        }
    }
    return nil;
}

- (void) presentAddSSIDAlert: (BOOL) whitelist {
    NSString *message = [NSString stringWithFormat:@"Add a WiFi SSID to the list of %@", whitelist ? @"networks to whitelist." : @"networks to blacklist."];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add a WiFi SSID" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        // only actually add it if it doesn't already exist in the list
        NSString *currentSSID = [AdvancedWiFiTableViewController getCurrentWifi];
        textField.placeholder = @"WiFi SSID";
        textField.secureTextEntry = NO;
        textField.text = currentSSID;
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"SSID %@", [[alertController textFields][0] text]);
        // save the SSID to the correct array

    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
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
        header.textLabel.textColor = [UIColor brand];
    }
}

@end


