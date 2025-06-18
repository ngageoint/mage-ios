//
//  LocationServicesSettingsTableViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "AppContainerScheming.h"

@interface ObservationServicesSettingsTableViewController : UITableViewController
- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;
@end

