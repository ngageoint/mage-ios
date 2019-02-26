//
//  SettingsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "SettingsDataSource.h"

@interface SettingsTableViewController : UITableViewController<CLLocationManagerDelegate>

@property (strong, nonatomic) SettingsDataSource *dataSource;

@end
