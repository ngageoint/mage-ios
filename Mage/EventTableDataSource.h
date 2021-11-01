//
//  EventTableDataSource.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol EventSelectionDelegate;

@interface EventTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) NSFetchedResultsController *otherFetchedResultsController;
@property(nonatomic, strong) NSFetchedResultsController *recentFetchedResultsController;
@property(nonatomic, strong) NSFetchedResultsController *filteredFetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet id<EventSelectionDelegate> eventSelectionDelegate;

- (void) startFetchController;
- (void) setEventFilter: (NSString *) filter withDelegate:(id<NSFetchedResultsControllerDelegate>) delegate;
- (void) refreshEventData;
- (id) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end
