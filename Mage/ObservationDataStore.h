//
//  ObservationDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "ObservationTableViewCell.h"
#import "Observations.h"
#import "ObservationSelectionDelegate.h"
#import <Event.h>

@interface ObservationDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, ObservationActionsDelegate>

@property (strong, nonatomic) Observations *observations;
@property (strong, nonatomic) Event *event;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<ObservationSelectionDelegate> observationSelectionDelegate;

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath;
- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView;

- (void) startFetchController;
- (void) startFetchControllerWithObservations: (Observations *) observations;
- (void) updatePredicates;

@end
