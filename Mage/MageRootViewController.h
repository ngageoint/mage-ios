//
//  MageRootViewController.h
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationFetchService.h"
#import "LocationFetchService.h"
#import "LocationService.h"
#import "ManagedObjectContextHolder.h"
#import "FetchServicesHolder.h"

@interface MageRootViewController : UITabBarController

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (strong, nonatomic) IBOutlet FetchServicesHolder *fetchServicesHolder;
@property (strong, nonatomic) LocationService *locationService;

@end
