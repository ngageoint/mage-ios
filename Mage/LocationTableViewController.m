//
//  PeopleViewController.m
//  Mage
//
//

#import "LocationTableViewController.h"
#import "Location.h"
#import "Event.h"
#import "MageSessionManager.h"
#import "TimeFilter.h"
#import "Filter.h"
#import "UINavigationItem+Subtitle.h"
#import "LocationFilterTableViewController.h"
#import "MAGE-Swift.h"

@interface LocationTableViewController() <UserSelectionDelegate>

@property (nonatomic, strong) NSTimer* updateTimer;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation LocationTableViewController

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
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : containerScheme.colorScheme.onPrimaryColor};
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: containerScheme.colorScheme.onPrimaryColor};
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
    self = [super initWithStyle:UITableViewStylePlain];
    self.scheme = containerScheme;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed)];
    
    if (!self.locationDataStore) {
        self.locationDataStore = [[LocationDataStore alloc] initWithScheme:self.scheme];
        self.tableView.dataSource = self.locationDataStore;
        self.tableView.delegate = self.locationDataStore;
        self.locationDataStore.tableView = self.tableView;
        if (self.delegate) {
            self.locationDataStore.personSelectionDelegate = self.delegate;
        }
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PersonCell" bundle:nil] forCellReuseIdentifier:@"personCell"];
    // ths is different on the ipad and the iphone so make the check here
    if (self.locationDataStore.personSelectionDelegate == nil) {
        self.locationDataStore.personSelectionDelegate = self;
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];

    [self.refreshControl addTarget:self action:@selector(refreshPeople) forControlEvents:UIControlEventValueChanged];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                forKey:NSForegroundColorAttributeName];
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Pull to refresh people" attributes:attrsDictionary]];
    
    self.tableView.refreshControl = self.refreshControl;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 72;
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationDataStore startFetchController];
    [self setNavBarTitle];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterNumberKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterUnitKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [self startUpdateTimer];
    [self updateFilterButtonPosition];
}

- (void) filterButtonPressed {
    UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"Filter" bundle:nil];
    LocationFilterTableViewController *fvc = [iphoneStoryboard instantiateViewControllerWithIdentifier:@"locationFilter"];
    [fvc applyThemeWithContainerScheme:self.scheme];
    [self.navigationController pushViewController:fvc animated:YES];
}

- (void) updateFilterButtonPosition {
    // This moves the filter and new button around based on if the view came from the morenavigationcontroller or not
    if (self != self.navigationController.viewControllers[0]) {
        if (self.navigationItem.rightBarButtonItem == nil) {
            self.navigationItem.rightBarButtonItem = self.navigationItem.leftBarButtonItem;
            self.navigationItem.leftBarButtonItem = nil;
        }
    } else if (self.navigationItem.rightBarButtonItem != nil) {
        self.navigationItem.leftBarButtonItem = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterUnitKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterNumberKey];
    
    [self stopUpdateTimer];
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
    [self.locationDataStore updatePredicates];
}

- (void) setNavBarTitle {
    NSString *timeFilterString = [Filter getLocationFilterString];
    [self.navigationItem setTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString scheme:self.scheme];
}

- (void) userDetailSelected:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (void) selectedUser:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (void) selectedUser:(User *)user region:(MKCoordinateRegion)region {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (void)refreshPeople {
    [self.refreshControl beginRefreshing];
    
    NSURLSessionDataTask *userFetchTask = [Location operationToPullLocationsWithSuccess:^{
        [self.refreshControl endRefreshing];
    } failure:^(NSError* error) {
        [self.refreshControl endRefreshing];
    }];
    
    [[MageSessionManager sharedManager] addTask:userFetchTask];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    
    if ([keyPath isEqualToString:kLocationTimeFilterKey] || [keyPath isEqualToString:kLocationTimeFilterNumberKey] || [keyPath isEqualToString:kLocationTimeFilterUnitKey]) {
        [self.locationDataStore startFetchController];
        [self setNavBarTitle];
    }
}


@end
