//
//  MageTabBarController.h
//  MAGE
//
//  Created by William Newman on 9/26/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapCalloutDelegate.h"

@interface MageTabBarController : UITabBarController

@property(nonatomic, weak) IBOutlet MapCalloutDelegate *userCalloutDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutDelegate *observationCalloutDelegate;

@end
