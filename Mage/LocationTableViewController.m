//
//  PeopleViewController.m
//  Mage
//
//

#import "LocationTableViewController.h"
#import "Location.h"
#import "MeViewController.h"
#import "Event.h"
#import "MageSessionManager.h"
#import "TimeFilter.h"
#import "Filter.h"
#import "UINavigationItem+Subtitle.h"
#import "Theme+UIResponder.h"

@interface LocationTableViewController() <UserSelectionDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) NSTimer* updateTimer;
@property (nonatomic, strong) id previewingContext;

@end

@implementation LocationTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor background];
    self.refreshControl.backgroundColor = [UIColor background];
    self.refreshControl.tintColor = [UIColor brand];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    [self setNavBarTitle];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
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
    
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    
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
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterUnitKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterNumberKey];
    
    [self stopUpdateTimer];
}

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    if ([self.presentedViewController isKindOfClass:[MeViewController class]]) {
        return nil;
    }
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        PersonTableViewCell *tableCell = (PersonTableViewCell *)[self.tableView cellForRowAtIndexPath:path];
        
        MeViewController *previewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MeViewController"];
        previewController.user = tableCell.user;
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

- (void)refreshPeople {
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
