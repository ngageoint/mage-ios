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

+ (Locations *) locationsForAllUsers;
+ (Locations *) locationsForUser:(User *) user;

+ (NSMutableArray *) getPredicatesForLocations;
- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
