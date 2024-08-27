//
//  Locations.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "ManagedObjectContextHolder.h"

@class Location;
@class User;

@interface Locations : NSObject

@property (nonatomic, weak) id<NSFetchedResultsControllerDelegate> delegate;
@property(nonatomic, strong)  NSFetchedResultsController  *fetchedResultsController;

+ (Locations *) locationsForAllUsers: (NSManagedObjectContext*) context;
+ (Locations *) locationsForUser:(User *) user context: (NSManagedObjectContext*) context;
+ (Locations *) locationsForMap: (NSManagedObjectContext*) context;

+ (NSMutableArray *) getPredicatesForLocations;
+ (NSMutableArray *) getPredicatesForLocationsForMap;
- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
