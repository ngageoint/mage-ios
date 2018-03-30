//
//  MapTypeTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 1/4/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapTypeTableViewCell.h"

@implementation MapTypeTableViewCell


- (IBAction)onMapTypeChanged:(UISegmentedControl *)segmentedControl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:segmentedControl.selectedSegmentIndex forKey:@"mapType"];
    [defaults synchronize];
}

@end
