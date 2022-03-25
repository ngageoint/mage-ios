//
//  EventChooserController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "EventTableDataSource.h"
#import <MaterialComponents/MaterialContainerScheme.h>
#import <MaterialComponents/MDCButton.h>

@class Event;

@protocol EventSelectionDelegate <NSObject>

-(void) didSelectEvent:(Event *) event;
-(void) actionButtonTapped;

@end

@interface EventChooserController : UIViewController<EventSelectionDelegate>

@property (weak, nonatomic) EventTableDataSource *eventDataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (nonatomic) BOOL passthrough;
@property (nonatomic) BOOL forcePick;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet MDCButton *actionButton;
@property (weak, nonatomic) id<EventSelectionDelegate> delegate;

- (instancetype) initWithDataSource: (EventTableDataSource *) eventDataSource andDelegate: (id<EventSelectionDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme;
- (void) eventsFetchedFromServer;
- (void) initializeView;

@end
