//
//  ObservationsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ObservationDataStore.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationTableViewController : UITableViewController <ObservationSelectionDelegate>

@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;
@property (weak, nonatomic) id<ObservationSelectionDelegate> observationSelectionDelegate;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end
