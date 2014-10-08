//
//  LocationSettingsTableViewController_iPad.h
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GPSSensitivityDataSource.h"
#import "LocationTimeIntervalDataSource.h"

@interface LocationSettingsTableViewController_iPad : UITableViewController<CLLocationManagerDelegate, GPSSensistivitySelected, LocationIntervalSelected>

@end
