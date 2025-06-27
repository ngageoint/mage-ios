//
//  AttributionsViewController.h
//  MAGE
//
//  Created by William Newman on 2/8/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppContainerScheming.h"

@interface AttributionsViewController : UITableViewController

- (instancetype) initWithScheme: (id<AppContainerScheming>)containerScheme;
- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
