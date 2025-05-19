//
//  Locations.m
//  MAGE
//
//

#import "Locations.h"
#import "TimeFilter.h"
#import "MAGE-Swift.h"

@implementation Locations

+ (NSMutableArray *) getPredicatesForLocationsForMap {
    NSMutableArray *predicates = [Locations getPredicatesForLocations];
    [predicates addObject:[NSPredicate predicateWithValue:![[NSUserDefaults standardUserDefaults] boolForKey:@"hidePeople"]]];
    return predicates;
}

+ (NSMutableArray *) getPredicatesForLocations {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *predicates = [NSMutableArray arrayWithObjects:
                                  [NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]],
//                                  [NSPredicate predicateWithFormat:@"user.remoteId != %@", [prefs valueForKey:@"currentUserId"]],
                                  nil];

    NSPredicate *timePredicate = [TimeFilter getLocationTimePredicateForField:@"timestamp"];
    if (timePredicate) {
        [predicates addObject:timePredicate];
    }
    return predicates;
}

+ (Locations *) locationsForAllUsers: (NSManagedObjectContext*) context {
    NSFetchRequest *fetchRequest = [Location fetchRequest];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[Locations getPredicatesForLocations]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Locations *) locationsForMap: (NSManagedObjectContext*) context {
    NSFetchRequest *fetchRequest = [Location fetchRequest];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[Locations getPredicatesForLocationsForMap]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (Locations *) locationsForUser:(User *) user context: (NSManagedObjectContext*) context {
    NSFetchRequest *fetchRequest = [Location fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user = %@ AND eventId == %@", user, [Server currentEventId]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
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
