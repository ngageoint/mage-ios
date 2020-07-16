//
//  Locations.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "ManagedObjectContextHolder.h"
#import "User.h"
#import "Location.h"

@interface Locations : NSObject

@property (nonatomic, weak) id<NSFetchedResultsControllerDelegate> delegate;
@property(nonatomic, strong)  NSFetchedResultsController <Location *> *fetchedResultsController;

+ (Locations *) locationsForAllUsers;
+ (Locations *) locationsForUser:(User *) user;

+ (NSMutableArray *) getPredicatesForLocations;
- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
