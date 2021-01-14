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
#import "ObservationViewController.h"
#import "ObservationTableViewCell.h"
#import "MAGE-Swift.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface ObservationTableViewController() <ObservationEditDelegate, AttachmentViewDelegate, AttachmentSelectionDelegate>

@property (nonatomic, strong) NSTimer* updateTimer;
// this property should exist in this view coordinator when we get to that
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation ObservationTableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme {
    if (containerScheme) {
        self.scheme = containerScheme;
    }
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.refreshControl.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.refreshControl.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.scheme.colorScheme.onPrimaryColor};
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor};
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
    
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.standardAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.scrollEdgeAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.prefersLargeTitles = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    [self setNavBarTitle];
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(createNewObservation:)];
    
    if (!self.observationDataStore) {
        self.observationDataStore = [[ObservationDataStore alloc] initWithScheme:self.scheme];
        self.tableView.dataSource = self.observationDataStore;
        self.tableView.delegate = self.observationDataStore;
        self.observationDataStore.tableView = self.tableView;
        if (self.attachmentDelegate) {
            self.observationDataStore.attachmentSelectionDelegate = self.attachmentDelegate;
        } else {
            self.observationDataStore.attachmentSelectionDelegate = self;
        }
        if (self.observationSelectionDelegate) {
            self.observationDataStore.observationSelectionDelegate = self.observationSelectionDelegate;
        }
    }
    
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
}

- (IBAction)createNewObservation:(id)sender {
    CLLocation *location = [[LocationService singleton] location];
    [self startCreateNewObservationAtLocation:location andProvider:@"gps"];
}

- (void) startCreateNewObservationAtLocation: (CLLocation *) location andProvider: (NSString *) provider {
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
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self delegate:self location:point accuracy:accuracy provider:provider delta:delta];
    [self.childCoordinators addObject:edit];
    [edit start];
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
    
    [self updateFilterButtonPosition];
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) updateFilterButtonPosition {
    // This moves the filter and new button around based on if the view came from the morenavigationcontroller or not
    if (self != self.navigationController.viewControllers[0]) {
        if (self.navigationItem.rightBarButtonItems.count != 2) {
            NSMutableArray *rightItems = [self.navigationItem.rightBarButtonItems mutableCopy];
            [rightItems addObject:self.navigationItem.leftBarButtonItem];
            self.navigationItem.rightBarButtonItems = rightItems;
            self.navigationItem.leftBarButtonItems = nil;
        }
    } else if (self.navigationItem.rightBarButtonItems.count == 2) {
        // if the view was in the more controller and is now it's own tab
        UIBarButtonItem *filterButton = [self.navigationItem.rightBarButtonItems lastObject];
        
        NSMutableArray *rightItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        [rightItems removeLastObject];
        self.navigationItem.rightBarButtonItems = rightItems;
        self.navigationItem.leftBarButtonItem = filterButton;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopUpdateTimer];
}

- (void) dealloc {
    self.observationDataStore.observations.delegate = nil;
}

- (void) filterButtonPressed {
    UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"Filter" bundle:nil];
    UIViewController *vc = [iphoneStoryboard instantiateViewControllerWithIdentifier:@"observationFilter"];
    [self.navigationController pushViewController:vc animated:YES];
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
    [self.navigationItem setTitle:@"Observations" subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString];
}

- (void) selectedObservation:(Observation *)observation {
    ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:observation];
    [ovc applyThemeWithScheme:self.scheme];
    [self.navigationController pushViewController:ovc animated:YES];
}

- (void) selectedObservation:(Observation *)observation region:(MKCoordinateRegion)region {
//    ObservationViewController *ovc = [[ObservationViewController alloc] init];
//    ovc.observation = observation;
    ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:observation];
    [ovc applyThemeWithScheme:self.scheme];
    [self.navigationController pushViewController:ovc animated:YES];
}

- (void) observationDetailSelected:(Observation *)observation {
//    ObservationViewController *ovc = [[ObservationViewController alloc] init];
//    ovc.observation = observation;
    ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:observation];
    [ovc applyThemeWithScheme:self.scheme];
    [self.navigationController pushViewController:ovc animated:YES];
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
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self delegate:self location:point accuracy:accuracy provider:@"gps" delta:delta];
    
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
    
    [[MageSessionManager sharedManager] addTask:observationFetchTask];
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
