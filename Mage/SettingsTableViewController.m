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
#import "SettingsDataSource.h"
#import "EventInformationCoordinator.h"
#import "AttributionsViewController.h"
#import "DisclaimerViewController.h"
#import "ThemeSettingsTableViewController.h"
#import "LocationDisplayTableViewController.h"
#import "TimeSettingsTableViewController.h"
#import "DataFetchSettingsTableViewController.h"
#import "LocationServicesSettingsTableViewController.h"

@interface SettingsTableViewController ()<AuthenticationDelegate, SettingsDelegate, EventInformationDelegate>
@property (strong, nonatomic) SettingsDataSource *dataSource;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL showDisclaimer;
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end

@implementation SettingsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [[SettingsDataSource alloc] init];
    self.dataSource.delegate = self;
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self.dataSource;
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    self.navigationController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.view.backgroundColor = [UIColor tableBackground];
    
    self.versionCellSelectionCount = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFromDetail:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.navigationController.view.backgroundColor = [UIColor tableBackground];

    [self.tableView reloadData];
}

- (void) updateFromDetail: (NSNotification *) notification {
    [self.tableView reloadData];
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) cancelLogin:(id) sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Authentication delegate

- (void)authenticationSuccessful {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

- (void)couldNotAuthenticate {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

# pragma mark - Settings delegate

- (void) settingTapped:(SettingType)setting info:(id) info {
    switch (setting) {
        case kConnection: {
            [self onLogin];
            break;
        }
        case kLocationServices: {
            LocationServicesSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationServices" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kDataFetching: {
            DataFetchSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"DataFetchingServices" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kLocationDisplay: {
            LocationDisplayTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationDisplay" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kTimeDisplay: {
            TimeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"TimeDisplay" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kEventInfo: {
            [self onEventInfo:info];
            break;
        }
        case kChangeEvent: {
            [self onChangeEvent:info];
            break;
        }
        case kMoreEvents: {
            [self onMoreEvents];
            break;
        }
        case kChangePassword: {
            [self onChangePassword];
            break;
        }
        case kLogout: {
            [self onLogout];
            break;
        }
        case kTheme: {
            ThemeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Themes" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kDisclaimer: {
            DisclaimerViewController *viewController = [[DisclaimerViewController alloc] initWithNibName:@"Disclaimer" bundle:nil];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case kAttributions: {
            AttributionsViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Attributions" owner:self options:nil][0];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
    }
}

# pragma mark - Event Information Coordinator Delegate

- (void) eventInformationComplete:(id) coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) onLogin {
    UINavigationController *nav = [[UINavigationController alloc] init];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    AuthenticationCoordinator *coord = [[AuthenticationCoordinator alloc] initWithNavigationController:nav andDelegate:self];
    [self.childCoordinators addObject:coord];
    [coord startLoginOnly];
    nav.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelLogin:)];
}

- (void) onEventInfo:(Event *)event {
    EventInformationCoordinator *coordinator = [[EventInformationCoordinator alloc] initWithViewController:self.navigationController event:event];
    [self.childCoordinators addObject:coordinator];
    coordinator.delegate = self;
    [coordinator start];
}

- (void) onChangeEvent:(Event *) event {
    [Event sendRecentEvent];
    [Server setCurrentEventId:event.remoteId];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIStoryboard *ipadStoryboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
        UIViewController *vc = [ipadStoryboard instantiateInitialViewController];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:vc animated:YES completion:NULL];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [iphoneStoryboard instantiateInitialViewController];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:vc animated:NO completion:^{
            NSLog(@"presented iphone storyboard");
        }];
    }
}

- (void) onLogout {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate logout];
}

- (void) onChangePassword {
    ChangePasswordViewController *vc = [[ChangePasswordViewController alloc] initWithLoggedIn:YES];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (void) onMoreEvents {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate chooseEvent];
}

@end
