//
//  PeopleViewController.m
//  Mage
//
//

#import "PeopleTableViewController.h"
#import "Location.h"
#import "MeViewController.h"
#import <Event+helper.h>
#import "HttpManager.h"

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
    [self.peopleDataStore startFetchController];
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


@end
