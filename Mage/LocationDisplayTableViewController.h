//
//  LocationDisplayTableViewController.h
//  MAGE
//
//  Created by Dan Barela on 9/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@interface LocationDisplayTableViewController : UITableViewController

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
