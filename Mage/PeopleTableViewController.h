//
//  PeopleViewController.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import <UIKit/UIKit.h>
#import "Locations.h"
#import "PeopleDataStore.h"
#import "ManagedObjectContextHolder.h"

@interface PeopleTableViewController : UIViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (strong, nonatomic) IBOutlet PeopleDataStore *peopleDataStore;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
