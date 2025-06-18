//
//  DataSynchronizationSettingsTableViewController.h
//  MAGE
//
//  Created by Daniel Barela on 1/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataSynchronizationSettingsTableViewController : UITableViewController

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END
