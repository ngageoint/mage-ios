//
//  EventChooserCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/7/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventChooserCoordinator.h"
#import "EventChooserController.h"
#import "Mage.h"
#import "Server.h"
#import "EventTableDataSource.h"
#import "UserUtility.h"
#import "FadeTransitionSegue.h"
#import "AppDelegate.h"

@interface EventChooserCoordinator() <EventSelectionDelegate>

@property (strong, nonatomic) EventTableDataSource *eventDataSource;
@property (strong, nonatomic) id<EventChooserDelegate> delegate;
@property (strong, nonatomic) EventChooserController<NSFetchedResultsControllerDelegate> *eventController;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) Event *eventToSegueTo;
@end

@implementation EventChooserCoordinator

- (instancetype) initWithViewController: (UIViewController *) viewController andDelegate: (id<EventChooserDelegate>) delegate {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
        self.delegate = delegate;
        self.viewController = viewController;
    }
    return self;
}

- (void) start {
    if ([Server currentEventId] != nil) {
        Event *event = [Event getEventById:[Server currentEventId] inContext:[NSManagedObjectContext MR_defaultContext]];
        self.eventToSegueTo = event;
        [self.eventController dismissViewControllerAnimated:NO completion:nil];
        [self.delegate eventChoosen:self.eventToSegueTo];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        return;
    }
    
    self.eventDataSource = [[EventTableDataSource alloc] init];
    self.eventController = [[EventChooserController<NSFetchedResultsControllerDelegate> alloc] initWithDataSource:self.eventDataSource andDelegate:self];
    [FadeTransitionSegue addFadeTransitionToView:self.viewController.view];
    __weak typeof(self) weakSelf = self;
    [self.viewController presentViewController:self.eventController animated:NO completion:^{
        [weakSelf.eventDataSource startFetchController];
        [weakSelf.eventController initializeView];
        weakSelf.eventDataSource.otherFetchedResultsController.delegate = weakSelf.eventController;
        weakSelf.eventDataSource.recentFetchedResultsController.delegate = weakSelf.eventController;
        [[Mage singleton] fetchEvents];
    }];
}

- (void) didSelectEvent:(Event *)event {
    self.eventToSegueTo = event;
    [self.eventController dismissViewControllerAnimated:NO completion:nil];
    [self.delegate eventChoosen:self.eventToSegueTo];
}

- (void) actionButtonTapped {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate logout];
}

- (void) eventsFetched: (NSNotification *) notification {
    [self.eventDataSource startFetchController];
    
    // does the user already have a current event?
    if ([Server currentEventId] != nil) {
        Event *event = [Event getEventById:[Server currentEventId] inContext:self.eventDataSource.recentFetchedResultsController.managedObjectContext];
        return [self didSelectEvent:event];
    }
    
    // does the user only have one event, and they have picked it? if so inform the delegate
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 &&
        self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1 &&
        [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].remoteId == ( (Event *)[self.eventDataSource.recentFetchedResultsController.fetchedObjects firstObject]).remoteId) {
        // they only have one event and have already picked it so move on to the map
        return [self didSelectEvent:self.eventToSegueTo];
    }
    
    // there is only one event and they have not picked it
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
        [Server setCurrentEventId:e.remoteId];
    }
    // they have zero events
    else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        [[UserUtility singleton] expireToken];
    }
    [self.eventController eventsFetched];
}


@end
