//
//  SettingsViewController.m
//  Mage
//
//

#import "SettingsTableViewController.h"
#import "User.h"
#import "LocationService.h"
#import "Server.h"
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

@interface SettingsTableViewController ()
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL showDisclaimer;
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@end

@implementation SettingsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [[SettingsDataSource alloc] init];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self.dataSource;
    self.clearsSelectionOnViewWillAppear = NO;
    
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    self.navigationController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.view.backgroundColor = [UIColor tableBackground];
    
    self.versionCellSelectionCount = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

@end
