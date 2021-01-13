//
//  DataSynchronizationSettingsTableViewController.h
//  MAGE
//
//  Created by Daniel Barela on 1/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MDCContainerScheme.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataSynchronizationSettingsTableViewController : UITableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END
