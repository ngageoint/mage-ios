//
//  MageSplitViewController.h
//  MAGE
//
//  Created by William Newman on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationService.h"

@interface MageSplitViewController : UISplitViewController

@property (strong, nonatomic) LocationService *locationService;

@end
