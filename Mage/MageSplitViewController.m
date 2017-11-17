//
//  MageSplitViewController.m
//  MAGE
//
//

#import "MageSplitViewController.h"
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "MapViewController_iPad.h"
#import "MageTabBarController.h"
#import "ObservationTableViewController.h"
#import "ObservationContainerViewController.h"
#import "LocationTableViewController.h"
#import "PeopleContainerViewController.h"
#import "MapCalloutTappedSegueDelegate.h"
#import "AttachmentViewController.h"
#import <Mage.h>

@interface MageSplitViewController () <AttachmentSelectionDelegate, UserSelectionDelegate, ObservationSelectionDelegate>
    @property(nonatomic, weak) MageTabBarController *tabBarController;
    @property(nonatomic, weak) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@end

@implementation MageSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[Mage singleton] startServicesAsInitial:YES];
    
    self.delegate = self;
    
    self.tabBarController = (MageTabBarController *) [self.viewControllers firstObject];

    UINavigationController *detailViewController = [self.viewControllers lastObject];
     
    self.mapViewController = (MapViewController_iPad *) detailViewController.topViewController;
    self.mapViewController.mapDelegate.mapCalloutDelegate = self.mapViewController;
    
    ObservationContainerViewController *observationViewController = (ObservationContainerViewController *) [self.tabBarController.viewControllers objectAtIndex:0];
    observationViewController.delegate = self;
    
    PeopleContainerViewController *peopleViewController = (PeopleContainerViewController *) [self.tabBarController.viewControllers objectAtIndex:1];
    peopleViewController.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        self.masterViewButton = self.displayModeButtonItem;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(orientation != UIInterfaceOrientationLandscapeLeft && orientation != UIInterfaceOrientationLandscapeRight) {
        [self ensureButtonVisible];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void) ensureButtonVisible {
    self.masterViewButton.title = @"List";
    self.masterViewButton.style = UIBarButtonItemStylePlain;
    
    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
    if (!items) {
        items = [NSMutableArray arrayWithObject:self.masterViewButton];
    } else if ([items objectAtIndex:0] != self.masterViewButton) {
        [items insertObject:self.masterViewButton atIndex:0];
    }
    
    [self.mapViewController.toolbar setItems:items];
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    NSLog(@"will change to display mode");
    
    self.masterViewButton = svc.displayModeButtonItem;
    if (displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
        NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
        [items removeObject:self.masterViewButton];
        [self.mapViewController.toolbar setItems:items];
        
        self.masterViewButton = nil;
        
        for (UIViewController *viewController in self.tabBarController.viewControllers) {
            [viewController.view setNeedsLayout];
        }
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    UIViewController *visibleViewController = [self.mapViewController.navigationController visibleViewController];
    if ([visibleViewController isKindOfClass:[AttachmentViewController class]]) {
        // ImageViewer already preset lets just update its content
        [((AttachmentViewController *) visibleViewController) setContent:attachment];
    } else {
        AttachmentViewController *attachmentVC = [[AttachmentViewController alloc] initWithAttachment:attachment];
        [attachmentVC setTitle:@"Attachment"];
        [self.mapViewController.navigationController pushViewController:attachmentVC animated:YES];
    }
}

@end
