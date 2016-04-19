//
//  ObservationFetchedResultsController.h
//  MAGE
//
//

#import <CoreData/CoreData.h>
#import "User.h"
#import "Observation.h"

@interface Observations : NSObject

@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, assign) id< NSFetchedResultsControllerDelegate > delegate;

+ (id) observations;
+ (id) observationsForUser:(User *) user;
+ (id) observationsForObservation:(Observation *) observation;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
