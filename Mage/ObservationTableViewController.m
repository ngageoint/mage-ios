//
//  ObservationsViewController.m
//  Mage
//
//

#import "ObservationTableViewController.h"
#import "UINavigationItem+Subtitle.h"
#import "TimeFilter.h"
#import "ObservationTableViewCell.h"
#import <Observation.h>
#import "MageRootViewController.h"
#import "AttachmentSelectionDelegate.h"
#import "AttachmentViewController.h"
#import "Event.h"
#import "User.h"
#import "ObservationEditViewController.h"
#import "MageSessionManager.h"
#import <LocationService.h>
#import "Filter.h"
#import "Observations.h"
#import "WKBPoint.h"

@implementation ObservationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // bug in ios smashes the refresh text into the
    // spinner.  This is the only work around I have found
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
    
    self.refreshControl.backgroundColor = [UIColor colorWithWhite:.9 alpha:.5];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 160;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // iOS bug fix.
    // For some reason the first view in a TabBarViewController when that TabBarViewController
    // is the master view of a split view the toolbar will not attach to the status bar correctly.
    // Forcing it to relayout seems to fix the issue.
    [self.view setNeedsLayout];
    
    [self setNavBarTitle];
    
    [self.observationDataStore startFetchController];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kImportantFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kFavortiesFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:kObservationTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kImportantFilterKey];
    [defaults removeObserver:self forKeyPath:kFavortiesFilterKey];
    
    self.observationDataStore.observations.delegate = nil;
}

- (void) setNavBarTitle {
    NSString *timeFilterString = [Filter getFilterString];
    [self.navigationItem setTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name subtitle:[timeFilterString isEqualToString:@"All"] ? nil : timeFilterString];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		Observation *observation = [self.observationDataStore observationAtIndexPath:indexPath];
		[destination setObservation:observation];
    } else if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        CLLocation *location = [[LocationService singleton] location];
        if (location != nil) {
            WKBPoint *point = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            [editViewController setLocation:point];
        }
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateNewObservationSegue"] || [identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        if (![[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"You are not part of this event"
                                         message:@"You cannot create observations for an event you are not part of."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];

            return false;
        }
    }
    return true;
}


- (IBAction)refreshObservations:(UIRefreshControl *)sender {
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
        [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:kObservationTimeFilterKey]) {
        [self.observationDataStore startFetchController];
        [self setNavBarTitle];
    } else if ([keyPath isEqualToString:kImportantFilterKey] || [keyPath isEqualToString:kFavortiesFilterKey]) {
        [self.observationDataStore startFetchController];
    }
}


@end
