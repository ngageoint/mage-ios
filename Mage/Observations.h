//
//  ObservationFetchedResultsController.h
//  MAGE
//
//

#import <CoreData/CoreData.h>

@class Observation;
@class User;

@interface Observations : NSObject
@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, weak) id< NSFetchedResultsControllerDelegate > delegate;

+ (BOOL) getImportantFilter;
+ (void) setImportantFilter:(BOOL) filter;

+ (BOOL) getFavoritesFilter;
+ (void) setFavoritesFilter:(BOOL) filter;


+ (Observations *) observations: (NSManagedObjectContext *) context;
+ (Observations *) list: (NSManagedObjectContext *) context;
+ (Observations *) observationsForMap: (NSManagedObjectContext *) context;
+ (Observations *) observationsForUser:(User *) user context: (NSManagedObjectContext *) context;
+ (Observations *) observationsForObservation:(Observation *) observation context: (NSManagedObjectContext *) context;

+ (NSMutableArray *) getPredicatesForObservations;
+ (NSMutableArray *) getPredicatesForObservationsForMap;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
