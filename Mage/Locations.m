//
//  Locations.m
//  MAGE
//
//

#import "Locations.h"
#import "Location.h"
#import "Server.h"
#import "TimeFilter.h"

@implementation Locations

+ (NSMutableArray *) getPredicatesForLocations {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *predicates = [NSMutableArray arrayWithObjects:
                                  [NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]],
                                  [NSPredicate predicateWithFormat:@"user.remoteId != %@", [prefs valueForKey:@"currentUserId"]],
                                  nil];

    NSPredicate *timePredicate = [TimeFilter getLocationTimePredicateForField:@"timestamp"];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    return predicates;
}

+ (id) locationsForAllUsers {
    
    
    NSFetchedResultsController *fetchedResultsController = [Location MR_fetchAllSortedBy:@"timestamp"
                        ascending:NO
                    withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[Locations getPredicatesForLocations]]
                          groupBy:nil
                         delegate:nil
                        inContext:[NSManagedObjectContext MR_defaultContext]];
    
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) locationsForUser:(User *) user {
    NSFetchedResultsController *fetchedResultsController = [Location MR_fetchAllSortedBy:@"timestamp"
                                                                               ascending:NO
                                                                           withPredicate:[NSPredicate predicateWithFormat:@"user = %@ AND eventId == %@", user, [Server currentEventId]]
                                                                                 groupBy:nil
                                                                                delegate:nil
                                                                               inContext:[NSManagedObjectContext MR_defaultContext]];
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}


- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController {
    if (self = [super init]) {
        self.fetchedResultsController = fetchedResultsController;
    }
    
    return self;
}

- (void) setDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    self.fetchedResultsController.delegate = delegate;
}

@end
