//
//  PeopleViewController.m
//  Mage
//
//

#import "PeopleTableViewController.h"
#import "Location.h"
#import "MeViewController.h"
#import <Event.h>
#import "HttpManager.h"
#import "TimeFilter.h"
#import "UINavigationItem+Subtitle.h"

@interface PeopleTableViewController ()
@property (weak, nonatomic) IBOutlet id<TimeFilterDelegate> timeFilterDelegate;
@end

@implementation PeopleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // bug in ios smashes the refresh text into the
    // spinner.  This is the only work around I have found
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
    
    Event *currentEvent = [Event getCurrentEvent];
    self.eventNameLabel.text = @"All";
    [self.navigationItem setTitle:currentEvent.name];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.peopleDataStore startFetchController];
    [self setNavBarTitle];
}

- (void) setNavBarTitle {
    NSString *timeFilterString = [TimeFilter getTimeFilterString];
    [self.navigationItem setTitle:[Event getCurrentEvent].name subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayPersonSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		Location *location = [self.peopleDataStore locationAtIndexPath:indexPath];
		[destination setUser:location.user];
    }
}

- (IBAction)refreshPeople:(UIRefreshControl *)sender {
    [self.refreshControl beginRefreshing];
    
    NSOperation *userFetchOperation = [User operationToFetchUsersWithSuccess:^{
        [self.refreshControl endRefreshing];
    } failure:^(NSError* error) {
        [self.refreshControl endRefreshing];
    }];
    
    [[HttpManager singleton].manager.operationQueue addOperation:userFetchOperation];
}

- (IBAction)showFilterActionSheet:(id)sender {
    __weak typeof(self) weakSelf = self;
    
    [self.timeFilterDelegate showFilterActionSheet:self complete:^(TimeFilterType timeFilter) {
        [TimeFilter setTimeFilter:timeFilter];
        [weakSelf.peopleDataStore startFetchController];
        [self setNavBarTitle];
    }];
}


@end
