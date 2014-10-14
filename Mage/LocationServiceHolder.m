
//
//  LocationServicesHolder.m
//  MAGE
//
//  Created by William Newman on 10/10/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationServiceHolder.h"
#import "AppDelegate.h"

@implementation LocationServiceHolder

- (id) init {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.locationService = appDelegate.locationService;
    return self;
}

@end
