//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//  Created by William Newman on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapCalloutTappedDelegate_iPhone.h"
#import "User.h"
#import "Observation.h"

@implementation MapCalloutTappedDelegate_iPhone

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self.userMapCalloutTappedDelegate calloutTapped:calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self.observationMapCalloutTappedDelegate calloutTapped:calloutItem];
    }
}

@end
