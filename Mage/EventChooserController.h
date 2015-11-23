//
//  EventChooserController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "EventTableDataSource.h"

@interface EventChooserController : UIViewController

@property (strong, nonatomic) IBOutlet EventTableDataSource *eventDataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (nonatomic) BOOL passthrough;
@property (nonatomic) BOOL forcePick;
@property (weak, nonatomic) IBOutlet UIView *loadingView;

@end
