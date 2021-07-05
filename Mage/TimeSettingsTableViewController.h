//
//  TimeSettingsTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 3/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@interface TimeSettingsTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
