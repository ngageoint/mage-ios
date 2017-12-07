//
//  ObservationFetchedResultsController.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "User.h"
#import "Observation.h"

@interface Observations : NSObject

extern NSString * const kImportantFilterKey;
extern NSString * const kFavortiesFilterKey;

@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, assign) id< NSFetchedResultsControllerDelegate > delegate;

+ (BOOL) getImportantFilter;
+ (void) setImportantFilter:(BOOL) filter;

+ (BOOL) getFavoritesFilter;
+ (void) setFavoritesFilter:(BOOL) filter;


+ (id) observations;
+ (id) observationsAscending: (BOOL) ascending;
+ (id) hideObservations;
+ (id) observationsForUser:(User *) user;
+ (id) observationsForObservation:(Observation *) observation;

+ (NSMutableArray *) getPredicatesForObservations;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
