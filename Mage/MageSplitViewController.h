//
//  MageSplitViewController.h
//  MAGE
//
//  Created by William Newman on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationService.h"
#import "LocationFetchService.h"
#import "ObservationFetchService.h"

@interface MageSplitViewController : UISplitViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) LocationService *locationService;
@property (strong, nonatomic) ObservationFetchService *observationFetchService;
@property (strong, nonatomic) LocationFetchService *locationFetchService;

@end
