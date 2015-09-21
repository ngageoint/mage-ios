//
//  ObservationViewController_iPhone.h
//  MAGE
//
//

#import <Observation+helper.h>
#import "AttachmentSelectionDelegate.h"

@interface ObservationViewController_iPhone : UIViewController <UITableViewDelegate, UITableViewDataSource, AttachmentSelectionDelegate>

@property (strong, nonatomic) Observation *observation;
@property (weak, nonatomic) IBOutlet UITableView *propertyTable;

@end
