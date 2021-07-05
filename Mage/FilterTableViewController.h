//
//  FilterTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 7/20/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MDCContainerScheme.h>

@interface FilterTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
