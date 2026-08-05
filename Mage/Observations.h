//
//  ObservationFetchedResultsController.h
//  MAGE
//
//

#import <CoreData/CoreData.h>

@interface Observations : NSObject
@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, weak) id< NSFetchedResultsControllerDelegate > delegate;

+ (BOOL) getImportantFilter;
+ (void) setImportantFilter:(BOOL) filter;

+ (BOOL) getFavoritesFilter;
+ (void) setFavoritesFilter:(BOOL) filter;


+ (Observations *) observations;
+ (Observations *) list;
+ (Observations *) observationsForMap;
+ (Observations *) hideObservations;
+ (Observations *) observationsForUser:(NSManagedObject *) user;
+ (Observations *) observationsForObservation:(NSManagedObject *) observation;

+ (NSMutableArray *) getPredicatesForObservations;
+ (NSMutableArray *) getPredicatesForObservationsForMap;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
