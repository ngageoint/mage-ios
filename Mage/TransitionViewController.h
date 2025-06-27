//
//  TransitionViewController.h
//  MAGE
//
//  Created by Dan Barela on 9/29/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@interface TransitionViewController : UIViewController

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
