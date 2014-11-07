//
//  MageRootViewController.h
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationFetchService.h"
#import "LocationFetchService.h"
#import "LocationServiceHolder.h"
#import "ManagedObjectContextHolder.h"
#import "FetchServicesHolder.h"

@interface MageRootViewController : UITabBarController

@property (weak, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet FetchServicesHolder *fetchServicesHolder;
@property (weak, nonatomic) IBOutlet LocationServiceHolder *locationServiceHolder;

@end
