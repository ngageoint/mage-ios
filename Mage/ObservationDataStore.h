//
//  ObservationDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "ObservationTableViewCell.h"
#import "Observations.h"
#import "ObservationSelectionDelegate.h"
#import "Event.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface ObservationDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, ObservationActionsDelegate_legacy>

@property (strong, nonatomic) Observations *observations;
@property (strong, nonatomic) Event *event;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<ObservationSelectionDelegate> observationSelectionDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (strong, nonatomic) UIViewController *viewController;

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath;
- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView;

- (id) initWithScheme :(id<MDCContainerScheming>) containerScheme;
- (void) startFetchController;
- (void) startFetchControllerWithObservations: (Observations *) observations;
- (void) updatePredicates;

@end
