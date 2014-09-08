//
//  DisclaimerNavigationController.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationFetchService.h"
#import "ObservationFetchService.h"

@interface DisclaimerNavigationController : UIViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) LocationFetchService *locationFetchService;
@property (strong, nonatomic) ObservationFetchService *observationFetchService;

@end
