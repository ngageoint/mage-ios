//
//  SignUpViewController.h
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignUpDelegate.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface SignUpViewController : UIViewController

- (instancetype) initWithDelegate: (id<SignupDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme;

@end
