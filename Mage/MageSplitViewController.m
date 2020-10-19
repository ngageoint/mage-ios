//
//  MageSplitViewController.m
//  MAGE
//
//

#import "MageSplitViewController.h"
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "MapViewController_iPad.h"
#import "ObservationTableViewController.h"
#import "FeedItemSelectionDelegate.h"
#import "LocationTableViewController.h"
#import "MapCalloutTappedSegueDelegate.h"
#import "MAGE-Swift.h"
#import "Mage.h"
#import "MAGE-Swift.h"

@interface MageSplitViewController () <AttachmentSelectionDelegate, UserSelectionDelegate, ObservationSelectionDelegate, AttachmentViewDelegate, FeedItemSelectionDelegate>
@property(nonatomic, strong) UINavigationController *masterViewController;
@property(nonatomic, strong) MageSideBarController *sideBarController;
    @property(nonatomic, strong) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) AttachmentViewCoordinator *attachmentCoordinator;

@end

@implementation MageSplitViewController

- (void) themeDidChange:(MageTheme)theme {
    self.masterViewController.navigationBar.barTintColor = [UIColor primary];
    self.masterViewController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    [self.masterViewController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor navBarPrimaryText]}];

    self.masterViewController.navigationBar.prefersLargeTitles = NO;
    self.masterViewController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setMaximumPrimaryColumnWidth:376];
    [self setPreferredPrimaryColumnWidthFraction:1.0];
    self.childCoordinators = [[NSMutableArray alloc] init];
    
    [[Mage singleton] startServicesAsInitial:YES];
    
    self.delegate = self;
        
    self.sideBarController = [[MageSideBarController alloc] init];
    self.sideBarController.delegate = self;
    self.masterViewController = [[UINavigationController alloc] initWithRootViewController:self.sideBarController];
    
    self.mapViewController = [[MapViewController_iPad alloc] init];
    UINavigationController *detailViewController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];
    
    self.viewControllers = [NSArray arrayWithObjects:self.masterViewController, detailViewController, nil];

    self.mapViewController.mapDelegate.mapCalloutDelegate = self.mapViewController;
    
    self.view.backgroundColor = [UIColor mageBlue];
    [self registerForThemeChanges];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.masterViewButton = self.displayModeButtonItem;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation != UIInterfaceOrientationLandscapeLeft && orientation != UIInterfaceOrientationLandscapeRight) {
        [self ensureButtonVisible];
    }
}

- (void)userDetailSelected:(User *) user {
    [[UIApplication sharedApplication] sendAction:self.masterViewButton.action to:self.masterViewButton.target from:nil forEvent:nil];
    [self.mapViewController userDetailSelected:user];
}

- (void)selectedUser:(User *) user {
    [self.mapViewController selectedUser:user];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    [self.mapViewController selectedUser:user region:region];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapViewController selectedObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapViewController selectedObservation:observation region:region];
}

- (void)observationDetailSelected:(Observation *)observation {
    [[UIApplication sharedApplication] sendAction:self.masterViewButton.action to:self.masterViewButton.target from:nil forEvent:nil];
    [self.mapViewController observationDetailSelected:observation];
}

- (void) feedItemSelected:(FeedItem *)feedItem {
    [[UIApplication sharedApplication] sendAction:self.masterViewButton.action to:self.masterViewButton.target from:nil forEvent:nil];
    [self.mapViewController feedItemSelected:feedItem];
}

- (void) ensureButtonVisible {
    self.masterViewButton.title = self.sideBarController.title;
    self.masterViewButton.style = UIBarButtonItemStylePlain;
    
    self.mapViewController.navigationItem.leftBarButtonItem = self.masterViewButton;
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    self.masterViewButton = svc.displayModeButtonItem;
    if (displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
        self.mapViewController.navigationItem.leftBarButtonItem = nil;
    }
}

- (void) doneViewingWithCoordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
    self.attachmentCoordinator = nil;
}

- (void) selectedAttachment:(Attachment *)attachment {
    if (self.attachmentCoordinator) {
        [self.attachmentCoordinator setAttachmentWithAttachment:attachment];
    } else {
        self.attachmentCoordinator = [[AttachmentViewCoordinator alloc] initWithRootViewController:self.mapViewController.navigationController attachment:attachment delegate:self];
        [self.childCoordinators addObject:self.attachmentCoordinator];
        [self.attachmentCoordinator start];
    }
}

@end
