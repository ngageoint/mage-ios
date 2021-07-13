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
@property (weak, nonatomic) id<EventChooserDelegate> delegate;
@property (strong, nonatomic) EventChooserController<NSFetchedResultsControllerDelegate> *eventController;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) Event *eventToSegueTo;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation EventChooserCoordinator

- (instancetype) initWithViewController: (UIViewController *) viewController andDelegate: (id<EventChooserDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
        self.delegate = delegate;
        self.viewController = viewController;
        self.scheme = containerScheme;
    }
    return self;
}

- (void) start {
    if ([Server currentEventId] != nil) {
        Event *event = [Event getEventById:[Server currentEventId] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (event != nil) {
            self.eventToSegueTo = event;
            [self.eventController dismissViewControllerAnimated:NO completion:nil];
            [self.delegate eventChoosen:self.eventToSegueTo];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            return;
        } else {
            [Server removeCurrentEventId];
        }
    }
    
    self.eventDataSource = [[EventTableDataSource alloc] initWithScheme:self.scheme];
    self.eventController = [[EventChooserController<NSFetchedResultsControllerDelegate> alloc] initWithDataSource:self.eventDataSource andDelegate:self andScheme:self.scheme];
    [FadeTransitionSegue addFadeTransitionToView:self.viewController.view];
    
    __weak typeof(self) weakSelf = self;
    [self.viewController presentViewController:self.eventController animated:NO completion:^{
        [weakSelf.eventDataSource startFetchController];
        [weakSelf.eventController initializeView];
        [[Mage singleton] fetchEvents];
    }];
}

- (void) didSelectEvent:(Event *)event {
    self.eventToSegueTo = event;
    [Server setCurrentEventId:event.remoteId];
    __weak typeof(self) weakSelf = self;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        // Save this event as the most recent one
        // this will get changed once it re-pulls from the server but that is fine
        Event *localEvent = [event MR_inContext:localContext];
        localEvent.recentSortOrder = [NSNumber numberWithInt:-1];
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        [weakSelf.eventController dismissViewControllerAnimated:NO completion:^{
            [weakSelf.delegate eventChoosen:weakSelf.eventToSegueTo];
        }];
    }];
}

- (void) actionButtonTapped {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate logout];
}

- (void) eventsFetched: (NSNotification *) notification {
    [self.eventController eventsFetchedFromServer];
}


@end
