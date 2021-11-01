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
#import "LocationDisplayTableViewController.h"
#import "TimeSettingsTableViewController.h"
#import "DataSynchronizationSettingsTableViewController.h"
#import "LocationServicesSettingsTableViewController.h"
#import "ObservationServicesSettingsTableViewController.h"
#import "Server.h"
#import "AppDelegate.h"
#import "MAGE-Swift.h"
#import <PureLayout/PureLayout.h>

@interface SettingsViewController ()<AuthenticationDelegate, SettingsDelegate, EventInformationDelegate, UISplitViewControllerDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) SettingsTableViewController *settingsTableViewController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) UINavigationController *masterViewController;
@property (strong, nonatomic) UIView *settingsDetailView;
@property (strong, nonatomic) UIImageView *settingsDetailImageView;
@property (strong, nonatomic) UILabel *settingsDetailLabel;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation SettingsViewController

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    
    return self;
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [super init]) {
        self.scheme = containerScheme;
        [self initialize];
    }
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }

    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.settingsDetailView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.settingsDetailImageView.tintColor = [self.scheme.colorScheme.primaryColor colorWithAlphaComponent:0.87];
    self.settingsDetailLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.87];
}

- (void) initialize {
    self.childCoordinators = [NSMutableArray array];
    
    self.settingsTableViewController = [[SettingsTableViewController alloc] initWithScheme:self.scheme delegate:self];
    self.masterViewController = [[UINavigationController alloc] initWithRootViewController:self.settingsTableViewController];
    
    self.settingsDetailView = [[UIView alloc] initForAutoLayout];
    
    UIViewController *detailViewController = [[UIViewController alloc] init];
    [detailViewController.view addSubview:self.settingsDetailView];
    [self.settingsDetailView autoPinEdgesToSuperviewEdges];
    self.settingsDetailImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"settings"]];
    [self.settingsDetailImageView autoSetDimensionsToSize:CGSizeMake(48, 48)];
    [self.settingsDetailView addSubview:self.settingsDetailImageView];
    [self.settingsDetailImageView autoCenterInSuperview];
    self.settingsDetailLabel = [[UILabel alloc] initForAutoLayout];
    [self.settingsDetailView addSubview:self.settingsDetailLabel];
    self.settingsDetailLabel.text = @"Settings";
    [self.settingsDetailLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.settingsDetailImageView withOffset:8];
    [self.settingsDetailLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    self.viewControllers = [NSArray arrayWithObjects:self.masterViewController, detailViewController, nil];
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
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
    if (splitViewController.collapsed == NO) {
        UIViewController *viewController = [splitViewController.viewControllers lastObject];
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *) viewController;
            [navigationController setViewControllers:@[vc]];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            navigationController.navigationBar.translucent = NO;
            navigationController.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
            navigationController.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
            navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.scheme.colorScheme.onPrimaryColor};
            navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor};
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithOpaqueBackground];
            appearance.titleTextAttributes = @{
                NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor,
                NSBackgroundColorAttributeName: self.scheme.colorScheme.primaryColorVariant
            };
            appearance.largeTitleTextAttributes = @{
                NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor,
                NSBackgroundColorAttributeName: self.scheme.colorScheme.primaryColorVariant
            };
            
            navigationController.navigationBar.standardAppearance = appearance;
            navigationController.navigationBar.scrollEdgeAppearance = appearance;
            navigationController.navigationBar.standardAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
            navigationController.navigationBar.scrollEdgeAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
            splitViewController.viewControllers = @[[splitViewController.viewControllers firstObject], navigationController];
        }
    } else {
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
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
            LocationServicesSettingsTableViewController *viewController = [[LocationServicesSettingsTableViewController alloc] initWithScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kObservationServices: {
            ObservationServicesSettingsTableViewController *viewController = [[ObservationServicesSettingsTableViewController alloc] initWithScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kDataSynchronization: {
            DataSynchronizationSettingsTableViewController *viewController = [[DataSynchronizationSettingsTableViewController alloc] initWithScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kLocationDisplay: {
            LocationDisplayTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationDisplay" owner:self options:nil][0];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kTimeDisplay: {
            TimeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"TimeDisplay" owner:self options:nil][0];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kMediaPhoto:
        case kMediaVideo: {
            NSString *preferenceKey = setting == kMediaPhoto ? @"imageUploadSizes" : @"videoUploadQualities";
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *fetchPreferences = [defaults dictionaryForKey:preferenceKey];
            
            ValuePickerTableViewController *viewController = [[ValuePickerTableViewController alloc] initWithScheme: self.scheme];
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
            ChangePasswordViewController *viewController = [[ChangePasswordViewController alloc] initWithLoggedIn:YES scheme:self.scheme];
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        case kLogout: {
            [self onLogout];
            break;
        }
            //        case kTheme: {
            //            ThemeSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Themes" owner:self options:nil][0];
            //            [self showDetailViewController:viewController sender:nil];
            //            break;
            //        }
        case kDisclaimer: {
            DisclaimerViewController *viewController = [[DisclaimerViewController alloc] initWithNibName:@"Disclaimer" bundle:nil];
            [viewController applyThemeWithContainerScheme:self.scheme];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kAttributions: {
            AttributionsViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"Attributions" owner:self options:nil][0];
            [viewController applyThemeWithContainerScheme:self.scheme];
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
    
    AuthenticationCoordinator *coord = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self andScheme:self.scheme];
    [self.childCoordinators addObject:coord];
    [coord startLoginOnly];
    navigationController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelLogin:)];
}

- (void) onEventInfo:(Event *)event {
    EventInformationCoordinator *coordinator = [[EventInformationCoordinator alloc] initWithViewController:[self.viewControllers firstObject] event:event scheme:self.scheme];
    [self.childCoordinators addObject:coordinator];
    coordinator.delegate = self;
    [coordinator startIpad];
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

- (void)changeServerUrl {
    
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
