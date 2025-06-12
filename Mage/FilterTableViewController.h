//
//  FilterTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 7/20/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@interface FilterTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
