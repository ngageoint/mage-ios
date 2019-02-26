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
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@end

@implementation SettingsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [[SettingsDataSource alloc] init];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self.dataSource;
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.versionCellSelectionCount = 0;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.view.backgroundColor = [UIColor tableBackground];
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

@end
