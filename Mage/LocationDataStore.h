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
#import <MaterialComponents/MaterialContainerScheme.h>

@interface LocationDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UserCellActionsDelegate>

@property (strong, nonatomic) Locations *locations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UserSelectionDelegate> personSelectionDelegate;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;
- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath;
- (void) startFetchController;
- (void) updatePredicates;

@end
