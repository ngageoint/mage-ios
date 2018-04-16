//
//  SettingsViewController.m
//  Mage
//
//

#import "SettingsTableViewController.h"
#import "User.h"
#import "LocationService.h"
#import "MageServer.h"
#import "EventChooserController.h"
#import "Event.h"
#import "NSDate+display.h"
#import "AppDelegate.h"
#import "EventChooserCoordinator.h"
#import "ChangePasswordViewController.h"
#import "AuthenticationCoordinator.h"
#import "ObservationTableHeaderView.h"
#import "Theme+UIResponder.h"

@interface SettingsTableViewController ()<UITableViewDelegate, AuthenticationDelegate>

    @property (weak, nonatomic) IBOutlet UILabel *locationServicesStatus;
@property (weak, nonatomic) IBOutlet UILabel *locationServicesLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchStatus;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageUploadSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *user;
@property (weak, nonatomic) IBOutlet UILabel *baseServerUrlLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (nonatomic, assign) BOOL showDisclaimer;
@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@property (weak, nonatomic) IBOutlet UITableViewCell *timeZoneSelectionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *eventCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *changePasswordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *goOnlineCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *themeCell;
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

static NSInteger legalSection = 6;

@implementation SettingsTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.locationServicesStatus.textColor = [UIColor secondaryText];
    self.dataFetchStatus.textColor = [UIColor secondaryText];
    self.dataFetchStatusLabel.textColor = [UIColor primaryText];
    self.locationServicesLabel.textColor = [UIColor primaryText];
    
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self registerForThemeChanges];
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    } else {
        // Fallback on earlier versions
    }
    
    self.versionCellSelectionCount = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFromDetail:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    self.user.text = user.name;
    
    Event *e = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
    self.eventNameLabel.text = e.name;

    [self setPreferenceDisplayLabel:self.imageUploadSizeLabel forPreference:@"imageUploadSizes"];
    [self populateSettingsTable];
}

- (void) updateFromDetail: (NSNotification *) notification {
    [self populateSettingsTable];
}

- (void) populateSettingsTable {
    [self setLocationServicesLabel];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.baseServerUrlLabel.text = [[MageServer baseURL] absoluteString];
    
    if ([[defaults objectForKey:@"dataFetchEnabled"] boolValue]) {
        [self.dataFetchStatus setText:@"On"];
    } else {
        [self.dataFetchStatus setText:@"Off"];
    }
    
    if (![NSDate isDisplayGMT]) {
        self.timeZoneSelectionCell.textLabel.text = @"Local Time";
        self.timeZoneSelectionCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSTimeZone systemTimeZone] name]];
    } else {
        self.timeZoneSelectionCell.textLabel.text = @"GMT Time";
        self.timeZoneSelectionCell.detailTextLabel.text = @"";
    }
    
    self.themeCell.detailTextLabel.text = [[[ThemeManager sharedManager] curentThemeDefinition] displayName];
}

- (void) setLocationServicesLabel {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    CLAuthorizationStatus authorizationStatus =[CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if ([defaults boolForKey:kReportLocationKey]) {
            [self.locationServicesStatus setText:@"On"];
        } else {
            [self.locationServicesStatus setText:@"Off"];
        }
    } else {
        [self.locationServicesStatus setText:@"Disabled"];
    }
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSArray *labels = [frequencyDictionary valueForKey:@"labels"];
    NSArray *values = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:[frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (int i = 0; i < values.count; i++) {
        if ([frequency integerValue] == [[values objectAtIndex:i] integerValue]) {
            [label setText:[labels objectAtIndex:i]];
            break;
        }
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setLocationServicesLabel];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.logoutCell) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate logout];
    } else if (cell == self.versionCell) {
        self.versionCellSelectionCount++;
        
        if (self.versionCellSelectionCount == 5) {
            [tableView reloadData];
        }
    } else if (cell == self.eventCell) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate chooseEvent];
    } else if (cell == self.changePasswordCell) {
        ChangePasswordViewController *vc = [[ChangePasswordViewController alloc] initWithLoggedIn:YES];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    } else if (cell == self.goOnlineCell) {
        UINavigationController *nav = [[UINavigationController alloc] init];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:nav animated:YES completion:nil];
        AuthenticationCoordinator *coord = [[AuthenticationCoordinator alloc] initWithNavigationController:nav andDelegate:self];
        [self.childCoordinators addObject:coord];
        [coord startLoginOnly];
        nav.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelLogin:)];

    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) cancelLogin:(id) sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    
    if ([indexPath section] == legalSection && [indexPath row] == 0) {
        cell.hidden = !self.showDisclaimer;
    } else if (cell == self.versionCell) {
        NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        if (self.versionCellSelectionCount == 5) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", versionString, buildString];
        } else {
            cell.detailTextLabel.text = versionString;
        }
    } else if (cell == self.goOnlineCell) {
        UILabel *offlineLabel = [[UILabel alloc] init];
        offlineLabel.font = [UIFont systemFontOfSize:14];
        offlineLabel.textAlignment = NSTextAlignmentCenter;
        offlineLabel.textColor = [UIColor whiteColor];
        offlineLabel.backgroundColor = [UIColor orangeColor];
        offlineLabel.text = @"!";
        [offlineLabel sizeToFit];
        // Adjust frame to be square for single digits or elliptical for numbers > 9
        CGRect frame = offlineLabel.frame;
        frame.size.height += (int)(0.4*14);
        frame.size.width = frame.size.height;
        offlineLabel.frame = frame;
        
        // Set radius and clip to bounds
        offlineLabel.layer.cornerRadius = frame.size.height/2.0;
        offlineLabel.clipsToBounds = true;
        
        // Show label in accessory view and remove disclosure
        cell.accessoryView = offlineLabel;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == legalSection && [indexPath row] == 0 && !self.showDisclaimer) {
        return 0;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            return UITableViewAutomaticDimension;
        }
        return 0.001;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            return UITableViewAutomaticDimension;
        }
        return 0.001;
    }
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            return nil;
        }
        return [[UIView alloc] init];
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            return nil;
        }
        return [[UIView alloc] init];
    }
    
    NSString *name = [self tableView:tableView titleForHeaderInSection:section];
    
    return [[ObservationTableHeaderView alloc] initWithName:name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0: {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
                return 1;
            }
            return 0;
        }
        case 1:
            return 2;
        case 2:
            return 1;
        case 3:
            return 1;
        case 4:
            return 3;
        case 5:
            return 3;
        case 6:
            return 2;
        default:
            break;
    }
    return 0;
}

- (void)authenticationSuccessful {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

- (void)couldNotAuthenticate {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

@end
