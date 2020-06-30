//
//  ObservationsViewController.m
//  Mage
//
//

#import "ObservationTableViewController.h"
#import "UINavigationItem+Subtitle.h"
#import "TimeFilter.h"
#import "ObservationTableViewCell.h"
#import "Observation.h"
#import "AttachmentSelectionDelegate.h"
#import "Event.h"
#import "User.h"
#import "ObservationEditViewController.h"
#import "MageSessionManager.h"
#import "LocationService.h"
#import "Filter.h"
#import "Observations.h"
#import "SFPoint.h"
#import "ObservationEditCoordinator.h"
#import "Theme+UIResponder.h"
#import "ObservationViewController.h"
#import "ObservationTableViewCell.h"
#import "MAGE-Swift.h"

@interface ObservationTableViewController() <ObservationEditDelegate, UIViewControllerPreviewingDelegate, AttachmentViewDelegate>

@property (nonatomic, strong) id previewingContext;
@property (nonatomic, strong) NSTimer* updateTimer;
// this property should exist in this view coordinator when we get to that
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

@implementation ObservationTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor background];
    self.refreshControl.backgroundColor = [UIColor background];
    self.refreshControl.tintColor = [UIColor brand];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    [self setNavBarTitle];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationCell" bundle:nil] forCellReuseIdentifier:@"obsCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TableSectionHeader" bundle:nil] forHeaderFooterViewReuseIdentifier:@"TableSectionHeader"];
    // this is different on the ipad on and the iphone so make the check here
    if (self.observationDataStore.observationSelectionDelegate == nil) {
        self.observationDataStore.observationSelectionDelegate = self;
    }
    
    self.observationDataStore.viewController = self;
    [self.observationDataStore startFetchController];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterNumberKey
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterUnitKey
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
    [defaults addObserver:self
               forKeyPath:kImportantFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
    [defaults addObserver:self
               forKeyPath:kFavortiesFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(refreshObservations) forControlEvents:UIControlEventValueChanged];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                forKey:NSForegroundColorAttributeName];
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Pull to refresh observations" attributes:attrsDictionary]];
    
    self.tableView.refreshControl = self.refreshControl;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64;
    
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // iOS bug fix.
    // For some reason the first view in a TabBarViewController when that TabBarViewController
    // is the master view of a split view the toolbar will not attach to the status bar correctly.
    // Forcing it to relayout seems to fix the issue.
    [self.view setNeedsLayout];
    
    [self setNavBarTitle];
    
    [self startUpdateTimer];
    
    [self registerForThemeChanges];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopUpdateTimer];
}

- (void) dealloc {
    self.observationDataStore.observations.delegate = nil;
}

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    if ([self.presentedViewController isKindOfClass:[ObservationViewController class]]) {
        return nil;
    }
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        ObservationTableViewCell *tableCell = (ObservationTableViewCell *)[self.tableView cellForRowAtIndexPath:path];

        ObservationViewController *previewController = [self.storyboard instantiateViewControllerWithIdentifier:@"observationViewerViewController"];
        previewController.observation = tableCell.observation;
        return previewController;
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    [self.navigationController showViewController:viewControllerToCommit sender:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self isForceTouchAvailable]) {
        if (!self.previewingContext) {
            self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    } else {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}

- (void) applicationWillResignActive {
    [self stopUpdateTimer];
}

- (void) applicationDidBecomeActive {
    [self startUpdateTimer];
}

- (void) startUpdateTimer {
    self.updateTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(onUpdateTimerFire) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.updateTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopUpdateTimer {
    // Stop the timer for updating the circles
    if (self.updateTimer != nil) {
        
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

- (void) onUpdateTimerFire {
    [self.observationDataStore updatePredicates];
}

- (void) setNavBarTitle {
    NSString *timeFilterString = [Filter getFilterString];
    [self.navigationItem setTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
		Observation *observation = (Observation *) sender;
		[destination setObservation:observation];
    }
}

- (void) selectedObservation:(Observation *)observation {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void) selectedObservation:(Observation *)observation region:(MKCoordinateRegion)region {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void) observationDetailSelected:(Observation *)observation {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (IBAction)newButtonTapped:(id)sender {
    CLLocation *location = [[LocationService singleton] location];

    ObservationEditCoordinator *edit;
    
    SFPoint *point;
    CLLocationAccuracy accuracy = 0;
    double delta = 0;
    if (location) {
        if (location.altitude != 0) {
            point = [[SFPoint alloc] initWithHasZ:YES andHasM:NO andX:[[NSDecimalNumber alloc] initWithDouble: location.coordinate.longitude] andY:[[NSDecimalNumber alloc] initWithDouble:location.coordinate.latitude]];
            [point setZValue:location.altitude];
        } else {
            point = [[SFPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
        }
        accuracy = location.horizontalAccuracy;
        delta = [location.timestamp timeIntervalSinceNow] * -1000;
    }
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self andDelegate:(id<ObservationEditDelegate>)self andLocation:point andAccuracy:accuracy andProvider:@"gps" andDelta:delta];

    [self.childCoordinators addObject:edit];
    [edit start];
}

- (void)refreshObservations {
    [self.refreshControl beginRefreshing];
    
    NSURLSessionDataTask *observationFetchTask = [Observation operationToPullObservationsWithSuccess:^{
        [self.refreshControl endRefreshing];
    } failure:^(NSError* error) {
        [self.refreshControl endRefreshing];
    }];
    
    [[MageSessionManager manager] addTask:observationFetchTask];
}

- (void) selectedAttachment:(Attachment *)attachment {
    if (self.attachmentDelegate != nil) {
        [self.attachmentDelegate selectedAttachment:attachment];
    } else {
        AttachmentViewCoordinator *attachmentCoordinator = [[AttachmentViewCoordinator alloc] initWithRootViewController:self.navigationController attachment:attachment delegate:self];
        [self.childCoordinators addObject:attachmentCoordinator];
        [attachmentCoordinator start];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:kObservationTimeFilterKey] || [keyPath isEqualToString:kObservationTimeFilterNumberKey] || [keyPath isEqualToString:kObservationTimeFilterUnitKey]) {
        [self.observationDataStore updatePredicates];
        [self setNavBarTitle];
    } else if ([keyPath isEqualToString:kImportantFilterKey] || [keyPath isEqualToString:kFavortiesFilterKey]) {
        [self.observationDataStore updatePredicates];
    }
}

- (void) editCancel:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void)editComplete:(Observation *)observation coordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) observationDeleted:(Observation *)observation coordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void)doneViewingWithCoordinator:(NSObject *)coordinator {
    // done viewing the attachment
    [self.childCoordinators removeObject:coordinator];
}


@end
