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
    NSPredicate *timePredicate = [Observations getTimePredicate];
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

+ (NSPredicate *) getTimePredicate {
    TimeFilterType timeFilter = [TimeFilter getTimeFilter];
    switch (timeFilter) {
        case TimeFilterLastHour: {
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:-1*60*60];
            return [NSPredicate predicateWithFormat:@"timestamp >= %@", date];
        }
        case TimeFilterLast6Hours: {
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:-6*60*60];
            return [NSPredicate predicateWithFormat:@"timestamp >= %@", date];
        }
        case TimeFilterLast12Hours: {
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:-12*60*60];
            return [NSPredicate predicateWithFormat:@"timestamp >= %@", date];
        }
        case TimeFilterLast24Hours: {
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:-24*60*60];
            return [NSPredicate predicateWithFormat:@"timestamp >= %@", date];
        }
        case TimeFilterToday: {
            NSDate *start = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];

            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.day = 1;
            components.second = -1;
            NSDate *end = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:NSCalendarMatchStrictly];
            
            return [NSPredicate predicateWithFormat:@"timestamp >= %@ && timestamp <= %@", start, end];
        }
        default: {
            return nil;
        }
    }
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
