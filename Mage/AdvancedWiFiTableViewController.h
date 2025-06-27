//
//  AdvancedWiFiTableViewController.h
//  MAGE
//
//  Created by Daniel Barela on 1/22/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdvancedWiFiTableViewController : UITableViewController

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END
