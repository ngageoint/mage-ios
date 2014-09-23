//
//  MageInitialViewController.h
//  Mage
//
//  Created by Dan Barela on 7/15/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationFetchService.h"
#import "ObservationFetchService.h"
#import "ManagedObjectContextHolder.h"

@interface MageInitialViewController : UIViewController

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (strong, nonatomic) LocationFetchService *locationFetchService;
@property (strong, nonatomic) ObservationFetchService *observationFetchService;

@end
