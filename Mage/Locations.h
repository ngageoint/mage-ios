//
//  Locations.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "ManagedObjectContextHolder.h"

@class Location;

@interface Locations : NSObject

@property (nonatomic, weak) id<NSFetchedResultsControllerDelegate> delegate;
@property(nonatomic, strong)  NSFetchedResultsController  *fetchedResultsController;

+ (Locations *) locationsForAllUsers;
+ (Locations *) locationsForUser:(NSManagedObject *) user;
+ (Locations *) locationsForMap;

+ (NSMutableArray *) getPredicatesForLocations;
+ (NSMutableArray *) getPredicatesForLocationsForMap;
- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
