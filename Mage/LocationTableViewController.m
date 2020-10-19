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
#import "Theme+UIResponder.h"
#import "MAGE-Swift.h"

@interface LocationTableViewController() <UserSelectionDelegate>

@property (nonatomic, strong) NSTimer* updateTimer;

@end

@implementation LocationTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.tableView.separatorColor = [UIColor tableSeparator];
    self.refreshControl.backgroundColor = [UIColor background];
    self.refreshControl.tintColor = [UIColor brand];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    [self setNavBarTitle];
}

- (instancetype) init {
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed)];
    
    if (!self.locationDataStore) {
        self.locationDataStore = [[LocationDataStore alloc] init];
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
    
    [self registerForThemeChanges];
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
    UIViewController *vc = [iphoneStoryboard instantiateViewControllerWithIdentifier:@"locationFilter"];
    [self.navigationController pushViewController:vc animated:YES];
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
    [self.navigationItem setTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString];
}

- (void) userDetailSelected:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (void) selectedUser:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (void) selectedUser:(User *)user region:(MKCoordinateRegion)region {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
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
