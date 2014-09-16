//
//  PeopleViewController.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import <UIKit/UIKit.h>
#import "LocationFetchedResultsController.h"
#import "PeopleDataStore.h"

@interface PeopleTableViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) IBOutlet PeopleDataStore *peopleDataStore;

@end
