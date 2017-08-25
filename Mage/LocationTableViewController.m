//
//  PeopleViewController.m
//  Mage
//
//

#import "LocationTableViewController.h"
#import "Location.h"
#import "MeViewController.h"
#import <Event.h>
#import "MageSessionManager.h"
#import "TimeFilter.h"
#import "Filter.h"
#import "UINavigationItem+Subtitle.h"

@interface LocationTableViewController() <UserSelectionDelegate>

@property (nonatomic, strong) NSTimer* updateTimer;

@end

@implementation LocationTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PersonCell" bundle:nil] forCellReuseIdentifier:@"personCell"];
    // ths is different on the ipad and the iphone so make the check here
    if (self.locationDataStore.personSelectionDelegate == nil) {
        self.locationDataStore.personSelectionDelegate = self;
    }
    
    // bug in ios smashes the refresh text into the
    // spinner.  This is the only work around I have found
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
    
    self.refreshControl.backgroundColor = [UIColor colorWithWhite:.9 alpha:.5];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88;
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
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(onUpdateTimerFire) userInfo:nil repeats:YES];
    });
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

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"ShowUserSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        User *user = (User *) sender;
		[destination setUser:user];
    }
}

- (void) userDetailSelected:(User *)user {
    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}

- (void) selectedUser:(User *)user {
    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}

- (void) selectedUser:(User *)user region:(MKCoordinateRegion)region {
    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}

- (IBAction)refreshPeople:(UIRefreshControl *)sender {
    [self.refreshControl beginRefreshing];
    
    NSURLSessionDataTask *userFetchTask = [Location operationToPullLocationsWithSuccess:^{
        [self.refreshControl endRefreshing];
    } failure:^(NSError* error) {
        [self.refreshControl endRefreshing];
    }];
    
    [[MageSessionManager manager] addTask:userFetchTask];
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
