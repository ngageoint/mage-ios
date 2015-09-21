//
//  DataFetchSettingsTableViewController_iPad.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "UserFetchDataSource.h"
#import "ObservationFetchDataSource.h"

@interface DataFetchSettingsTableViewController_iPad : UITableViewController<UserFetchIntervalSelected, ObservationFetchIntervalSelected>

@end
