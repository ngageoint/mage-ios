//
//  MageSplitViewController.h
//  MAGE
//
//  Created by William Newman on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationService.h"
#import "ManagedObjectContextHolder.h"
#import "FetchServicesHolder.h"
#import "MapCalloutTappedSegueDelegate.h"
#import "LocationServiceHolder.h"

@interface MageSplitViewController : UISplitViewController<UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet FetchServicesHolder *fetchServicesHolder;
@property (weak, nonatomic) IBOutlet LocationServiceHolder *locationServiceHolder;

@end
