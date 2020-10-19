//
//  SettingsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import "SettingsDataSource.h"

@interface SettingsTableViewController : UITableViewController

@property (strong, nonatomic) SettingsDataSource *dataSource;
@property (nonatomic, assign) BOOL dismissable;

@end
