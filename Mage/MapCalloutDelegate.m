//
//  MapCalloutDelegate.m
//  MAGE
//
//  Created by William Newman on 9/26/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapCalloutDelegate.h"
#import "User+helper.h"
#import "Observation+helper.h"

@implementation MapCalloutDelegate

-(void) calloutTapped:(id) calloutItem {
    [self.viewController performSegueWithIdentifier:self.segueIdentifier sender:calloutItem];
}

@end
