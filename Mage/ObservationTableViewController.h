//
//  ObservationsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ObservationDataStore.h"
#import "AttachmentSelectionDelegate.h"
#import "ObservationEditCoordinator.h"

@interface ObservationTableViewController : UITableViewController <ObservationSelectionDelegate>

@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

@end
