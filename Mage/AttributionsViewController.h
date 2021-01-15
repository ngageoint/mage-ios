//
//  AttributionsViewController.h
//  MAGE
//
//  Created by William Newman on 2/8/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@interface AttributionsViewController : UITableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>)containerScheme;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
