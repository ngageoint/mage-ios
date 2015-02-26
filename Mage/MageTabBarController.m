//
//  MageTabBarController.m
//  MAGE
//
//  Created by William Newman on 9/26/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageTabBarController.h"
#import "MeViewController.h"
#import "ObservationViewController.h"

@implementation MageTabBarController

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    UINavigationController *navigationController = [self navigationController];
    [navigationController popToRootViewControllerAnimated:NO];
    
    if ([[segue identifier] isEqualToString:@"DisplayPersonFromMapSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        [destination setUser:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationFromMapSegue"]) {
        ObservationViewController *destination = (ObservationViewController *)[segue destinationViewController];
        [destination setObservation:sender];
    }
}

@end
