//
//  SettingsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import "SettingsDataSource.h"
#import <MaterialComponents/MDCContainerScheme.h>

@interface SettingsTableViewController : UITableViewController

@property (strong, nonatomic) SettingsDataSource *dataSource;
@property (nonatomic, assign) BOOL dismissable;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end
