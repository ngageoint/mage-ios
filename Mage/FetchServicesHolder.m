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
    AppDelegate *appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.locationFetchService = appdelegate.locationFetchService;
    self.observationFetchService = appdelegate.observationFetchService;
    
    return self;
}

@end
