//
//  SettingsViewController.m
//  Mage
//
//

#import "SettingsTableViewController.h"
#import "MAGE-Swift.h"
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

#import "SettingsDataSource.h"
#import "AuthenticationCoordinator.h"
#import "EventInformationCoordinator.h"
#import "AttributionsViewController.h"
#import "DisclaimerViewController.h"
#import "LocationDisplayTableViewController.h"
#import "TimeSettingsTableViewController.h"
#import "DataSynchronizationSettingsTableViewController.h"
#import "LocationServicesSettingsTableViewController.h"
#import "ObservationServicesSettingsTableViewController.h"

@interface SettingsTableViewController ()<AuthenticationDelegate, SettingsDelegate, EventInformationDelegate, UISplitViewControllerDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (weak, nonatomic) id<SettingsDelegate> delegate;
@end

@implementation SettingsTableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme delegate: (id<SettingsDelegate>) delegate {
    if (self = [self initWithStyle:UITableViewStyleGrouped]) {
        self.scheme = containerScheme;
        self.delegate = delegate;
    }
    return self;
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [self initWithStyle:UITableViewStyleGrouped]) {
        self.scheme = containerScheme;
    }
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.navigationController.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    self.dataSource = [[SettingsDataSource alloc] initWithScheme:self.scheme];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self.dataSource;
    self.tableView.estimatedSectionFooterHeight = 45;
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.dataSource.showDisclosureIndicator = YES;
    
    self.dataSource.delegate = self.delegate ? self.delegate : self;
    
    self.versionCellSelectionCount = 0;
    
    if (self.dismissable) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}

-(void) done:(UIBarButtonItem *) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showSetting: (UIViewController *) vc {
    UINavigationController *navigationController = self.navigationController;
    vc.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [navigationController pushViewController:vc animated:YES];
}

# pragma mark - Settings delegate

- (void)settingTapped:(SettingType)setting info:(nonnull id)info {
    switch (setting) {
        case kConnection: {
            [self onLogin];
            break;
        }
        case kLocationServices: {
            LocationServicesSettingsTableViewController *viewController = [[LocationServicesSettingsTableViewController alloc] initWithScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kObservationServices: {
            ObservationServicesSettingsTableViewController *viewController = [[ObservationServicesSettingsTableViewController alloc] initWithScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kDataSynchronization: {
            DataSynchronizationSettingsTableViewController *viewController = [[DataSynchronizationSettingsTableViewController alloc] initWithScheme: self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kLocationDisplay: {
            LocationDisplayTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationDisplay" owner:self options:nil][0];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kTimeDisplay: {
            TimeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"TimeDisplay" owner:self options:nil][0];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kMediaPhoto:
        case kMediaVideo: {
            NSString *preferenceKey = setting == kMediaPhoto ? @"imageUploadSizes" : @"videoUploadQualities";
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *fetchPreferences = [defaults dictionaryForKey:preferenceKey];
            
            ValuePickerTableViewController *viewController = [[ValuePickerTableViewController alloc] initWithScheme: self.scheme];
            [viewController applyThemeWithContainerScheme:self.scheme];
            viewController.title = [fetchPreferences valueForKey:@"title"];
            viewController.section = [fetchPreferences valueForKey:@"section"];
            viewController.labels = [fetchPreferences valueForKey:@"labels"];
            viewController.values = [fetchPreferences valueForKey:@"values"];
            viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
            [self showSetting:viewController];
            
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
            ChangePasswordViewController *viewController = [[ChangePasswordViewController alloc] initWithLoggedIn:YES scheme:self.scheme];
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        case kLogout: {
            [self onLogout];
            break;
        }
        case kNavigation: {
            NavigationSettingsViewController *viewController = [[NavigationSettingsViewController alloc] initWithScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kDisclaimer: {
            DisclaimerViewController *viewController = [[DisclaimerViewController alloc] initWithNibName:@"Disclaimer" bundle:nil];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
        case kAttributions: {
            AttributionsViewController *viewController = [[AttributionsViewController alloc] initWithScheme: self.scheme];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showSetting:viewController];
            break;
        }
    }
}

- (void) onLogin {
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
    AuthenticationCoordinator *coord = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self andScheme:self.scheme];
    [self.childCoordinators addObject:coord];
    [coord startLoginOnly];
    navigationController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelLogin:)];
}

- (void) onEventInfo:(Event *)event {
    UINavigationController *navigationController = self.navigationController;
    EventInformationCoordinator *coordinator = [[EventInformationCoordinator alloc] initWithViewController:navigationController event:event scheme: self.scheme];
    
    [self.childCoordinators addObject:coordinator];
    coordinator.delegate = self;
    [coordinator start];
}

- (void) onChangeEvent:(Event *) event {
    [Event sendRecentEvent];
    [Server setCurrentEventId:event.remoteId];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate createRootView];
}

- (void) onLogout {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate logout];
}

- (void) onMoreEvents {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate chooseEvent];
}

# pragma mark - Event Information Coordinator Delegate

- (void) eventInformationComplete:(id) coordinator {
    [self.childCoordinators removeObject:coordinator];
}

# pragma mark - Authentication delegate

- (void)authenticationSuccessful {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.dataSource reloadData];
    [self.tableView reloadData];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [AuthenticationCoordinator class]];
    self.childCoordinators = [[self.childCoordinators filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void)couldNotAuthenticate {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.dataSource reloadData];
    [self.tableView reloadData];
}

- (void) cancelLogin:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [AuthenticationCoordinator class]];
    self.childCoordinators = [[self.childCoordinators filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void)changeServerUrl {
    
}

# pragma mark - NSNotification delegate

- (void) userDefaultsChanged: (NSNotification *) notification {
    [self.dataSource reloadData];
    [self.tableView reloadData];
}

# pragma mark - CLLocationManager delegate

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.dataSource reloadData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}


@end
