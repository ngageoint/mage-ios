//
//  SettingsViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import "SettingsDataSource.h"
#import "AppContainerScheming.h"

@interface SettingsTableViewController : UITableViewController

@property (strong, nonatomic) SettingsDataSource *dataSource;
@property (nonatomic, assign) BOOL dismissable;

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;
- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme delegate: (id<SettingsDelegate>) delegate context: (NSManagedObjectContext *) context;

@end
