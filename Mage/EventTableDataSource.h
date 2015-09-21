//
//  EventTableDataSource.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface EventTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong)  NSFetchedResultsController *otherFetchedResultsController;
@property(nonatomic, strong)  NSFetchedResultsController *recentFetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void) startFetchController;

@end
