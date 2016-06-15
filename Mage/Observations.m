//
//  ObservationFetchedResultsController.m
//  MAGE
//
//

#import "Observations.h"
#import "Observation.h"
#import "Server.h"
#import "TimeFilter.h"

@implementation Observations

+ (id) observations {
    
    NSMutableArray *predicates = [NSMutableArray arrayWithObject:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];
    NSPredicate *timePredicate = [TimeFilter getTimePredicateForField:@"timestamp"];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                  managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                    sectionNameKeyPath:@"sectionName"
                             cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) observationsForUser:(User *) user {
    NSFetchRequest *fetchRequest = [Observation MR_requestAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"user == %@ AND eventId == %@", user, [Server currentEventId]]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:@"sectionName"
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
