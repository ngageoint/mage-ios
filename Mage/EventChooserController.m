//
//  EventChooserController.m
//  MAGE
//
//  Created by Dan Barela on 3/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventChooserController.h"
#import <Event+helper.h>
#import <Mage.h>
#import <Server+helper.h>

@implementation EventChooserController

- (void) viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
    [[Mage singleton] initiateDataPull];
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
    if (self.eventDataSource.allFetchedResultsController.fetchedObjects.count == 0) {
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        
        messageLabel.text = @"You are not in any events.  You must be part of an event to use MAGE.  Contact your administrator to be added to an event.";
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:20];
        
        self.tableView.backgroundView = messageLabel;
        
        self.actionButton.titleLabel.text = @"Return to Login";
    } else if (self.eventDataSource.allFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1) {
        // they only have one event and have already picked it so move on to the map
        [self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:self];
    } else if (self.eventDataSource.allFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.allFetchedResultsController.fetchedObjects objectAtIndex:0];
        [Server setCurrentEventId:e.remoteId];
        [self.tableView reloadData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayRootViewSegue"]) {
        [Event sendRecentEvent];
    }
}

@end
