//
//  EventChooserCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/7/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventChooserCoordinator.h"
#import "EventChooserController.h"
#import <Mage.h>
#import <Server.h>
#import "EventTableDataSource.h"
#import <UserUtility.h>
#import "FadeTransitionSegue.h"

@interface EventChooserCoordinator() <EventSelectionDelegate>

@property (strong, nonatomic) EventTableDataSource *eventDataSource;
@property (strong, nonatomic) id<EventChooserDelegate> delegate;
@property (strong, nonatomic) EventChooserController *eventController;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) NSMutableArray *formsFetched;
@property (strong, nonatomic) Event *eventToSegueTo;
@end

@implementation EventChooserCoordinator

- (instancetype) initWithViewController: (UIViewController *) viewController andDelegate: (id<EventChooserDelegate>) delegate {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(formFetched:) name:MAGEFormFetched object:nil];
        self.delegate = delegate;
        self.viewController = viewController;
        self.formsFetched = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) start {
    self.eventDataSource = [[EventTableDataSource alloc] init];
    self.eventController = [[EventChooserController alloc] initWithDataSource:self.eventDataSource andDelegate:self];
    [FadeTransitionSegue addFadeTransitionToView:self.viewController.view];
    [self.viewController presentViewController:self.eventController animated:NO completion:nil];
    [[Mage singleton] fetchEvents];

}

- (void) didSelectEvent:(Event *)event {
//    if (!checkForms) {
//        [self.delegate didSelectEvent:eventToSegueTo];
//    }
    
    // first ensure the form for that event was pulled or else we will just wait for the form fetched notification
    self.eventToSegueTo = event;
    if ([self.formsFetched containsObject:event.remoteId]) {
        [self.eventController dismissViewControllerAnimated:NO completion:nil];
        [self.delegate eventChoosen:self.eventToSegueTo];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) formFetched: (NSNotification *) notification {
    Event *event = (Event *)notification.object;
    if (self.eventToSegueTo && [self.eventToSegueTo.remoteId isEqualToNumber:event.remoteId]) {
        [self.eventController dismissViewControllerAnimated:NO completion:nil];
        [self.delegate eventChoosen:self.eventToSegueTo];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [self.formsFetched addObject:event.remoteId];
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
