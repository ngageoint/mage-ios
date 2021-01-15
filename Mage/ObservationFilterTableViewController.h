//
//  FilterTableViewController.h
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MDCContainerScheme.h>

@interface ObservationFilterTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
