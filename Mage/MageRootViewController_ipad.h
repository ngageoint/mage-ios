//
//  MageRootViewController_ipad.h
//  MAGE
//
//  Created by William Newman on 9/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ObservationFetchService.h"
#import "LocationFetchService.h"
#import "LocationService.h"
#import "ManagedObjectContextHolder.h"
#import "FetchServicesHolder.h"

@interface MageRootViewController_ipad : UINavigationController

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (strong, nonatomic) IBOutlet FetchServicesHolder *fetchServicesHolder;
@property (strong, nonatomic) LocationService *locationService;

@end
