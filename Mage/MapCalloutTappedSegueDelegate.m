//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//  Created by William Newman on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapCalloutTappedSegueDelegate.h"
#import "User.h"
#import "observation.h"

@implementation MapCalloutTappedSegueDelegate

-(void) calloutTapped:(id) calloutItem {
    [self.viewController performSegueWithIdentifier:self.segueIdentifier sender:calloutItem];
}

@end
