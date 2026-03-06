//
//  ObservationFetchedResultsController.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "TimeFilter.h"

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

+ (NSMutableArray *) getPredicatesForObservations: (NSManagedObjectContext *) context;
+ (NSMutableArray *) getPredicatesForObservations: (NSManagedObjectContext *) context timeFilter:(TimeFilterType) timeFilter customUnit:(TimeUnit) unit customNumber:(NSInteger) number;
+ (NSMutableArray *) getPredicatesForObservationsForMap: (NSManagedObjectContext *) context;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
