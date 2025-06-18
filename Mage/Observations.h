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


+ (Observations *) observations;
+ (Observations *) list;
+ (Observations *) observationsForMap;
+ (Observations *) hideObservations;
+ (Observations *) observationsForUser:(User *) user;
+ (Observations *) observationsForObservation:(Observation *) observation;

+ (NSMutableArray *) getPredicatesForObservations;
+ (NSMutableArray *) getPredicatesForObservationsForMap;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
