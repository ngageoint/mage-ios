//
//  ObservationFetchedResultsController.m
//  MAGE
//
//

#import "Observations.h"
#import "Observation+Section.h"
#import "Server.h"
#import "TimeFilter.h"

@implementation Observations

NSString * const kImportantFilterKey = @"importantFilterKey";
NSString * const kFavortiesFilterKey = @"favortiesFilterKey";

+ (BOOL) getImportantFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:kImportantFilterKey];
}

+ (void) setImportantFilter:(BOOL) filter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:filter forKey:kImportantFilterKey];
    [defaults synchronize];
}

+ (BOOL) getFavoritesFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:kFavortiesFilterKey];
}

+ (void) setFavoritesFilter:(BOOL) filter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:filter forKey:kFavortiesFilterKey];
    [defaults synchronize];
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
        User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"favorites.favorite CONTAINS %@ AND favorites.userId CONTAINS %@", [NSNumber numberWithBool:YES], currentUser.remoteId]];
    }
    
    return predicates;
}

+ (id) observations {
    return [Observations observationsAscending:NO];
}

+ (id) observationsAscending: (BOOL) ascending {
    NSMutableArray *predicates = [Observations getPredicatesForObservations];
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:ascending withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) hideObservations {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSPredicate predicateWithValue:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dateSection"
                                                                                                          cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) observationsForUser:(User *) user {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"dirty,timestamp" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"user == %@ AND eventId == %@", user, [Server currentEventId]]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"dirtySection"
                                                                                                          cacheName:nil];
    
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) observationsForObservation:(Observation *) observation {
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
