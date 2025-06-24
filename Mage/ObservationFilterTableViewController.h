//
//  FilterTableViewController.h
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@interface ObservationFilterTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
