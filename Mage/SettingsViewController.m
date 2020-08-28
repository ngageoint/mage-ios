//
//  MainSettingsViewController.m
//  MAGE
//
//  Created by William Newman on 11/7/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsTableViewController.h"
#import "SettingsDataSource.h"
#import "AuthenticationCoordinator.h"
#import "EventInformationCoordinator.h"
#import "AttributionsViewController.h"
#import "ChangePasswordViewController.h"
#import "DisclaimerViewController.h"
#import "ThemeSettingsTableViewController.h"
#import "LocationDisplayTableViewController.h"
#import "TimeSettingsTableViewController.h"
#import "DataFetchSettingsTableViewController.h"
#import "DataSynchronizationSettingsTableViewController.h"
#import "LocationServicesSettingsTableViewController.h"
#import "ObservationServicesSettingsTableViewController.h"
#import "Server.h"
#import "AppDelegate.h"
#import "Theme+UIResponder.h"
#import "MAGE-swift.h"

@interface SettingsViewController ()<AuthenticationDelegate, SettingsDelegate, EventInformationDelegate, UISplitViewControllerDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) SettingsTableViewController *settingsTableViewController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end

@implementation SettingsViewController

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    
    return self;
}

- (instancetype) init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void) initialize {
    self.childCoordinators = [NSMutableArray array];
    
    self.settingsTableViewController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
//    [[NSBundle mainBundle] loadNibNamed:@"SettingsMasterView" owner:self options:nil][0];
    self.settingsTableViewController.dataSource.delegate = self;
    UINavigationController *masterViewController = [[UINavigationController alloc] initWithRootViewController:self.settingsTableViewController];
    
    UIViewController *detailViewController = [[UIViewController alloc] initWithNibName:@"SettingsDetailView" bundle:nil];
    self.viewControllers = [NSArray arrayWithObjects:masterViewController, detailViewController, nil];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    
    self.delegate = self;
    
    if (self.dismissable) {
        UINavigationController *masterController = [self.viewControllers firstObject];
        masterController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.view.backgroundColor = [UIColor tableBackground];
    self.view.backgroundColor = [UIColor tableBackground];
    
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
    if (splitViewController.collapsed == NO) {
        UIViewController *viewController = [splitViewController.viewControllers lastObject];
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *) viewController;
            [navigationController setViewControllers:@[vc]];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            splitViewController.viewControllers = @[[splitViewController.viewControllers firstObject], navigationController];
        }
    } else {
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        vc.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        [navigationController pushViewController:vc animated:YES];
    }
    
    return YES;
}

-(BOOL) splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    self.settingsTableViewController.dataSource.showDisclosureIndicator = YES;
    [self.settingsTableViewController.tableView reloadData];

    return nil;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    self.settingsTableViewController.dataSource.showDisclosureIndicator = NO;
    [self.settingsTableViewController.tableView reloadData];

    return nil;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    UINavigationController *navigationController = (UINavigationController *) primaryViewController;
    [navigationController popToRootViewControllerAnimated:NO];
    return [[UIViewController alloc] initWithNibName:@"SettingsDetailView" bundle:nil];
}

-(void) done:(UIBarButtonItem *) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Settings delegate

- (void)settingTapped:(SettingType)setting info:(nonnull id)info {
    switch (setting) {
        case kConnection: {
            [self onLogin];
            break;
        }
        case kLocationServices: {
            LocationServicesSettingsTableViewController *viewController = [[LocationServicesSettingsTableViewController alloc] init];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kObservationServices: {
            ObservationServicesSettingsTableViewController *viewController = [[ObservationServicesSettingsTableViewController alloc] init];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kDataSynchronization: {
            DataSynchronizationSettingsTableViewController *viewController = [[DataSynchronizationSettingsTableViewController alloc] init];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kLocationDisplay: {
            LocationDisplayTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationDisplay" owner:self options:nil][0];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kTimeDisplay: {
            TimeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"TimeDisplay" owner:self options:nil][0];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kMediaPhoto:
        case kMediaVideo: {
            NSString *preferenceKey = setting == kMediaPhoto ? @"imageUploadSizes" : @"videoUploadQualities";
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *fetchPreferences = [defaults dictionaryForKey:preferenceKey];
            
            ValuePickerTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"ValuePicker" owner:self options:nil][0];
            viewController.title = [fetchPreferences valueForKey:@"title"];
            viewController.section = [fetchPreferences valueForKey:@"section"];
            viewController.labels = [fetchPreferences valueForKey:@"labels"];
            viewController.values = [fetchPreferences valueForKey:@"values"];
            viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
            [self showDetailViewController:viewController sender:nil];
            
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
            ChangePasswordViewController *viewController = [[ChangePasswordViewController alloc] initWithLoggedIn:YES];
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        case kLogout: {
            [self onLogout];
            break;
        }
        case kTheme: {
            ThemeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Themes" owner:self options:nil][0];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kDisclaimer: {
            DisclaimerViewController *viewController = [[DisclaimerViewController alloc] initWithNibName:@"Disclaimer" bundle:nil];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kAttributions: {
            AttributionsViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Attributions" owner:self options:nil][0];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
    }
}

- (void) onLogin {
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    [self presentViewController:navigationController animated:YES completion:nil];
    
    AuthenticationCoordinator *coord = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self];
    [self.childCoordinators addObject:coord];
    [coord startLoginOnly];
    navigationController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelLogin:)];
}

- (void) onEventInfo:(Event *)event {
    EventInformationCoordinator *coordinator = [[EventInformationCoordinator alloc] initWithViewController:[self.viewControllers firstObject] event:event];
    [self.childCoordinators addObject:coordinator];
    coordinator.delegate = self;
    [coordinator start];
}

- (void) onChangeEvent:(Event *) event {
    [Event sendRecentEvent];
    [Server setCurrentEventId:event.remoteId];
    
    MageRootViewController *vc = [[MageRootViewController alloc] init];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:NULL];
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
    [self.settingsTableViewController.dataSource reloadData];
    [self.settingsTableViewController.tableView reloadData];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [AuthenticationCoordinator class]];
    self.childCoordinators = [[self.childCoordinators filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void)couldNotAuthenticate {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.settingsTableViewController.dataSource reloadData];
    [self.settingsTableViewController.tableView reloadData];
}

- (void) cancelLogin:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [AuthenticationCoordinator class]];
    self.childCoordinators = [[self.childCoordinators filteredArrayUsingPredicate:predicate] mutableCopy];
}

# pragma mark - NSNotification delegate

- (void) userDefaultsChanged: (NSNotification *) notification {
    [self.settingsTableViewController.dataSource reloadData];
    [self.settingsTableViewController.tableView reloadData];
}

# pragma mark - CLLocationManager delegate

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.settingsTableViewController.dataSource reloadData];
    [self.settingsTableViewController.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

@end
