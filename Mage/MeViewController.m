//
//  MeViewController.m
//  MAGE
//
//  Created by Dan Barela on 10/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MeViewController.h"

@interface MeViewController ()

@end

@implementation MeViewController

- (IBAction)dismissMe:(id)sender {
    NSLog(@"Done");
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
