//
//  PeopleViewController.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import <UIKit/UIKit.h>
#import "Locations.h"
#import "PeopleDataStore.h"
#import "MAGEMasterSelectionDelegate.h"

@interface PeopleTableViewController : UIViewController

@property (strong, nonatomic) IBOutlet PeopleDataStore *peopleDataStore;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet id<MAGEMasterSelectionDelegate> masterSelectionDelegate;

@end
