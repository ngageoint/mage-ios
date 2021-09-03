//
//  MageSplitViewController.m
//  MAGE
//
//

#import "MageSplitViewController.h"
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "MapViewController_iPad.h"
#import "FeedItemSelectionDelegate.h"
#import "Mage.h"
#import "MAGE-Swift.h"

@interface MageSplitViewController () <AttachmentSelectionDelegate, UserSelectionDelegate, ObservationSelectionDelegate, AttachmentViewDelegate, FeedItemSelectionDelegate, ObservationActionsDelegate>
@property(nonatomic, strong) UINavigationController *masterViewController;
@property(nonatomic, strong) UINavigationController *detailViewController;
@property(nonatomic, strong) MageSideBarController *sideBarController;
    @property(nonatomic, strong) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) AttachmentViewCoordinator *attachmentCoordinator;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation MageSplitViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }

    self.masterViewController.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
    self.masterViewController.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
    [self.masterViewController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:containerScheme.colorScheme.onPrimaryColor}];

    self.masterViewController.navigationBar.prefersLargeTitles = NO;
    self.masterViewController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.detailViewController.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
    self.detailViewController.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
    [self.detailViewController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:containerScheme.colorScheme.onPrimaryColor}];
    
    self.detailViewController.navigationBar.prefersLargeTitles = NO;
    self.detailViewController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.view.backgroundColor = containerScheme.colorScheme.surfaceColor;
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super init];
    self.scheme = containerScheme;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setMaximumPrimaryColumnWidth:426];
    [self setPreferredPrimaryColumnWidthFraction:1.0];
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.childCoordinators = [[NSMutableArray alloc] init];
    
    [[Mage singleton] startServicesAsInitial:YES];
    
    self.delegate = self;
        
    self.sideBarController = [[MageSideBarController alloc] initWithContainerScheme:self.scheme];
    self.sideBarController.delegate = self;
    self.masterViewController = [[UINavigationController alloc] initWithRootViewController:self.sideBarController];
    
    self.mapViewController = [[MapViewController_iPad alloc] initWithScheme:self.scheme];
    self.detailViewController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];
    
    self.viewControllers = [NSArray arrayWithObjects:self.masterViewController, self.detailViewController, nil];

    self.mapViewController.mapDelegate.mapCalloutDelegate = self.mapViewController;
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.masterViewButton = self.displayModeButtonItem;
    
    if(!UIWindow.isLandscape) {
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
        self.attachmentCoordinator = [[AttachmentViewCoordinator alloc] initWithRootViewController:self.mapViewController.navigationController attachment:attachment delegate:self scheme:_scheme];
        [self.childCoordinators addObject:self.attachmentCoordinator];
        [self.attachmentCoordinator start];
    }
}

- (void)selectedUnsentAttachment:(NSDictionary *)unsentAttachment {
    self.attachmentCoordinator = [[AttachmentViewCoordinator alloc] initWithRootViewController:self.mapViewController.navigationController url:unsentAttachment[@"localPath"] contentType: unsentAttachment[@"contentType"] delegate:self scheme:_scheme];
    [self.attachmentCoordinator start];
}


@end
