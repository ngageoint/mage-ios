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

+ (NSMutableArray *) getPredicatesForObservationsForMap: (NSManagedObjectContext *) context {
    NSMutableArray *predicates = [Observations getPredicatesForObservations: context];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [predicates addObject:[NSPredicate predicateWithValue:!defaults.hideObservations]];
    return predicates;
}

+ (NSMutableArray *) getPredicatesForObservations: (NSManagedObjectContext *) context {
    NSMutableArray *predicates = [NSMutableArray arrayWithObject:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];
    NSPredicate *timePredicate = [TimeFilter getObservationTimePredicateForField:@"timestamp"];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    
    if ([Observations getImportantFilter]) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"observationImportant.important = %@", [NSNumber numberWithBool:YES]]];
    }
    
    if ([Observations getFavoritesFilter]) {
        User *currentUser = [User fetchCurrentUserWithContext:context];
        [predicates addObject:[NSPredicate predicateWithFormat:@"favorites.favorite CONTAINS %@ AND favorites.userId CONTAINS %@", [NSNumber numberWithBool:YES], currentUser.remoteId]];
    }
    
    return predicates;
}

// Purely for swift because calling Observations.observations() is impossible
+ (Observations *) list: (NSManagedObjectContext *) context {
    return [Observations observations:context];
}

+ (Observations *) observations: (NSManagedObjectContext *) context {
    NSMutableArray *predicates = [Observations getPredicatesForObservations: context];
    NSFetchRequest *fetchRequest = [Observation fetchRequest];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForMap: (NSManagedObjectContext *) context {
    NSMutableArray *predicates = [Observations getPredicatesForObservationsForMap: context];
    NSFetchRequest *fetchRequest = [Observation fetchRequest];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) hideObservations: (NSManagedObjectContext *) context {
    NSFetchRequest *fetchRequest = [Observation fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithValue:NO];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForUser:(User *) user context: (NSManagedObjectContext *) context {
    NSFetchRequest *fetchRequest = [Observation fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user == %@ AND eventId == %@", user, [Server currentEventId]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dirty" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"dirtySection"
                                                                                                          cacheName:nil];
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Observations *) observationsForObservation:(Observation *) observation context: (NSManagedObjectContext *) context {
    NSFetchRequest *fetchRequest = [Observation fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(self = %@)", observation];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
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
