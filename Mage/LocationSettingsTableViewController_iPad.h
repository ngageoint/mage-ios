//
//  LocationSettingsTableViewController_iPad.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GPSSensitivityDataSource.h"
#import "LocationTimeIntervalDataSource.h"

@interface LocationSettingsTableViewController_iPad : UITableViewController<CLLocationManagerDelegate, GPSSensistivitySelected, LocationIntervalSelected>

@end
