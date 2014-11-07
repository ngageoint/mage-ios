//
//  FetchServicesHolder.m
//  MAGE
//
//  Created by Dan Barela on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FetchServicesHolder.h"
#import "AppDelegate.h"

@implementation FetchServicesHolder

- (id) init {
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    
    self.locationFetchService = appDelegate.locationFetchService;
    self.observationFetchService = appDelegate.observationFetchService;
    self.observationPushService = appDelegate.observationPushService;
    
    return self;
}

@end
