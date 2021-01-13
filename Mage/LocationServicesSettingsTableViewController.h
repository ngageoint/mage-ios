//
//  LocationServicesSettingsTableViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MaterialComponents/MDCContainerScheme.h>

@interface LocationServicesSettingsTableViewController : UITableViewController<CLLocationManagerDelegate>

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end
