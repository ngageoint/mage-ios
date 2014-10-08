//
//  DataFetchSettingsTableViewController_iPad.h
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserFetchDataSource.h"
#import "ObservationFetchDataSource.h"

@interface DataFetchSettingsTableViewController_iPad : UITableViewController<UserFetchIntervalSelected, ObservationFetchIntervalSelected>

@end
