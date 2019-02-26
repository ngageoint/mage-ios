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
#import "LocationServicesSettingsTableViewController.h"
#import "Server.h"
#import "AppDelegate.h"

@interface SettingsViewController ()<AuthenticationDelegate, SettingsDelegate, EventInformationDelegate, UISplitViewControllerDelegate>
@property (strong, nonatomic) SettingsTableViewController *settingsTableViewController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end

@implementation SettingsViewController

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.childCoordinators = [NSMutableArray array];
        
        self.settingsTableViewController = [[NSBundle mainBundle] loadNibNamed:@"SettingsMasterView" owner:self options:nil][0];
        self.settingsTableViewController.dataSource.delegate = self;
        UINavigationController *masterViewController = [[UINavigationController alloc] initWithRootViewController:self.settingsTableViewController];
        
        UIViewController *detailViewController = [[UIViewController alloc] initWithNibName:@"SettingsDetailView" bundle:nil];
        self.viewControllers = [NSArray arrayWithObjects:masterViewController, detailViewController, nil];
    }
    
    return self;
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    self.delegate = self;
    
    if (self.collapsed) {
        NSLog(@"yp");
    }
    
    if (self.dismissable) {
        UINavigationController *masterController = [self.viewControllers firstObject];
        masterController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
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
        UINavigationController *navigationContoller = [splitViewController.viewControllers lastObject];
        [navigationContoller pushViewController:vc animated:YES];
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
            LocationServicesSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"LocationServices" owner:self options:nil][0];
            [self showDetailViewController:viewController sender:nil];
            break;
        }
        case kDataFetching: {
            DataFetchSettingsTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"DataFetchingServices" owner:self options:nil][0];
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
            [self showDetailViewController:viewController sender:nil];
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
    
    NSString *storyboardName = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"Main_iPad" : @"Main_iPhone";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    UIViewController *initialViewController = [storyboard instantiateInitialViewController];
    initialViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:initialViewController animated:YES completion:NULL];
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

@end
