//
//  Locations.m
//  MAGE
//
//

#import "Locations.h"
#import "TimeFilter.h"
#import "MAGE-Swift.h"

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

+ (Locations *) locationsForAllUsers {
    
    
    NSFetchedResultsController *fetchedResultsController = [Location MR_fetchAllSortedBy:@"timestamp"
                        ascending:NO
                    withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[Locations getPredicatesForLocations]]
                          groupBy:nil
                         delegate:nil
                        inContext:[NSManagedObjectContext MR_defaultContext]];
    
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Locations *) locationsForUser:(User *) user {
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
