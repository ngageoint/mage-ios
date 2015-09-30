//
//  EventChooserController.m
//  MAGE
//
//

#import "EventChooserController.h"
#import <Event+helper.h>
#import <Mage.h>
#import <Server+helper.h>

@implementation EventChooserController

BOOL unwind = NO;

- (void) viewDidAppear:(BOOL) animated {
    if (self.passthrough) {
        self.passthrough = NO;
        [self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:self];
    } else if (!unwind) {
        self.loadingView.alpha = 1.0f;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
        [[Mage singleton] fetchEvents];
    } else {
        [self eventsFetched:nil];
        unwind = NO;
    }
}

- (void) viewDidDisappear:(BOOL) animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)actionButtonTapped:(id)sender {
    if ([Server currentEventId]) {
        [self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:sender];
    } else {
        [self performSegueWithIdentifier:@"unwindToInitialSegue" sender:sender];
    }
}

- (void) eventsFetched: (NSNotification *) notification {
    NSLog(@"Events were fetched");
    [self.eventDataSource startFetchController];
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        
        messageLabel.text = @"You are not in any events.  You must be part of an event to use MAGE.  Contact your administrator to be added to an event.";
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:20];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundView = messageLabel;
        
        self.actionButton.titleLabel.text = @"Return to Login";
    } else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 &&
               self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1 &&
               [Event getCurrentEvent].remoteId == ( (Event *)[self.eventDataSource.recentFetchedResultsController.fetchedObjects firstObject]).remoteId) {
        // they only have one event and have already picked it so move on to the map
        [self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:self];
    } else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
        [Server setCurrentEventId:e.remoteId];
        [self.tableView reloadData];
    } else {
        [self.tableView reloadData];
    }
    
    [UIView animateWithDuration:0.75f animations:^{
        self.loadingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.loadingView.alpha = 0.0;
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayRootViewSegue"]) {
        [Event sendRecentEvent];
    }
}

- (IBAction) unwindToEventChooser:(UIStoryboardSegue *) unwindSegue {
    unwind = YES;
}

@end
