//
//  MageTabBarController.h
//  MAGE
//
//  Created by William Newman on 9/26/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapCalloutTappedSegueDelegate.h"

@interface MageTabBarController : UITabBarController

@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *userMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *observationMapCalloutTappedDelegate;

@end
