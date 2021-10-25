//
//  ThemeTableViewController.h
//  MAGE
//
//  Created by Daniel Barela on 10/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MaterialComponents/MaterialContainerScheme.h>

@interface ThemeTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
