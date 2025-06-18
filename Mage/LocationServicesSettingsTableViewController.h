//
//  LocationServicesSettingsTableViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "AppContainerScheming.h"

@protocol LocationServicesDelegate
- (void) openSettingsTapped;
@end

@interface LocationServicesSettingsTableViewController : UITableViewController<CLLocationManagerDelegate>

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;

@end
