//
//  GridTypeTableViewCell.m
//  MAGE
//
//  Created by Brian Osborn on 9/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GridTypeTableViewCell.h"

@implementation GridTypeTableViewCell


- (IBAction)onGridTypeChanged:(UISegmentedControl *)segmentedControl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:segmentedControl.selectedSegmentIndex forKey:@"gridType"];
    [defaults synchronize];

    [self.delegate gridTypeChanged:segmentedControl.selectedSegmentIndex];
}

@end
