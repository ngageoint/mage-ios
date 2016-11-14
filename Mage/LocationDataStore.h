//
//  PeopleDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "Location.h"
#import "PersonTableViewCell.h"
#import "Locations.h"
#import "UserSelectionDelegate.h"

@interface LocationDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Locations *locations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UserSelectionDelegate> personSelectionDelegate;

- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath;
- (void) startFetchController;

@end
