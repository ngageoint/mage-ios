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

+ (id) locationsForAllUsers {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *predicates = [NSMutableArray arrayWithObjects:
                                  [NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]],
                                  [NSPredicate predicateWithFormat:@"user.remoteId != %@", [prefs valueForKey:@"currentUserId"]],
                                  nil];

    NSPredicate *timePredicate = [Locations getTimePredicate];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    
    NSFetchedResultsController *fetchedResultsController = [Location MR_fetchAllSortedBy:@"timestamp"
                        ascending:NO
                    withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]
                          groupBy:nil
                         delegate:nil
                        inContext:[NSManagedObjectContext MR_defaultContext]];
    
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
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
