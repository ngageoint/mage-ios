//
//  PeopleViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Locations.h"
#import "LocationDataStore.h"
#import "MAGEMasterSelectionDelegate.h"

@interface LocationTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet LocationDataStore *locationDataStore;
@property (nonatomic, assign) IBOutlet id<MAGEMasterSelectionDelegate> masterSelectionDelegate;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

@end
