//
//  EventChooserController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "EventTableDataSource.h"

@class Event;

@protocol EventSelectionDelegate <NSObject>

-(void) didSelectEvent:(Event *) event;

@end

@interface EventChooserController : UIViewController<EventSelectionDelegate>

@property (strong, nonatomic) EventTableDataSource *eventDataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (nonatomic) BOOL passthrough;
@property (nonatomic) BOOL forcePick;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) id<EventSelectionDelegate> delegate;

- (instancetype) initWithDataSource: (EventTableDataSource *) eventDataSource andDelegate: (id<EventSelectionDelegate>) delegate;
- (void) eventsFetched;

@end
