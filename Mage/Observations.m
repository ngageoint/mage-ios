//
//  ObservationFetchedResultsController.m
//  MAGE
//
//

#import "Observations.h"
#import "Observation+Section.h"
#import "TimeFilter.h"
#import "MAGE-Swift.h"

@implementation Observations

+ (BOOL) getImportantFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.importantFilterKey;
}

+ (void) setImportantFilter:(BOOL) filter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.importantFilterKey = filter;
    [defaults synchronize];
}

+ (BOOL) getFavoritesFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults.favoritesFilterKey;
}

+ (void) setFavoritesFilter:(BOOL) filter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.favoritesFilterKey = filter;
    [defaults synchronize];
}

+ (NSMutableArray *) getPredicatesForObservationsForMap {
    NSMutableArray *predicates = [Observations getPredicatesForObservations];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [predicates addObject:[NSPredicate predicateWithValue:!defaults.hideObservations]];
    return predicates;
}

+ (NSMutableArray *) getPredicatesForObservations {
    NSMutableArray *predicates = [NSMutableArray arrayWithObject:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];
    NSPredicate *timePredicate = [TimeFilter getObservationTimePredicateForField:@"timestamp"];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    
    if ([Observations getImportantFilter]) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"observationImportant.important = %@", [NSNumber numberWithBool:YES]]];
    }
    
    if ([Observations getFavoritesFilter]) {
        User *currentUser = [User fetchCurrentUserWithContext:[NSManagedObjectContext MR_defaultContext]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"favorites.favorite CONTAINS %@ AND favorites.userId CONTAINS %@", [NSNumber numberWithBool:YES], currentUser.remoteId]];
    }
    
    return predicates;
}

// Purely for swift because calling Observations.observations() is impossible
+ (Observations *) list {
    return [Observations observations];
}

+ (Observations *) observations {
    NSMutableArray *predicates = [Observations getPredicatesForObservations];
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForMap {
    NSMutableArray *predicates = [Observations getPredicatesForObservationsForMap];
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:YES withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) hideObservations {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSPredicate predicateWithValue:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForUser:(User *) user {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"dirty,timestamp" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"user == %@ AND eventId == %@", user, [Server currentEventId]]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dirtySection"
                                                                                                          cacheName:nil];
    
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForObservation:(Observation *) observation {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"(self = %@)", observation]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}


- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController {
    if (self = [super init]) {
        self.fetchedResultsController = fetchedResultsController;
    }
    
    return self;
}

-(void) setDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    self.fetchedResultsController.delegate = delegate;
}

@end
