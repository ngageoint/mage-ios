//
//  ObservationsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ObservationDataStore.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

@end
