//
//  SettingsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface SettingsTableViewController : UITableViewController<CLLocationManagerDelegate>

@property (assign, nonatomic) BOOL showDisclosureIndicator;

@end
