//
//  SignUpViewController.m
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SignUpViewController.h"
#import "SignUpTableViewController.h"

@interface SignUpViewController ()

@end

@implementation SignUpViewController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"SignUpEmbedSegue"]) {
        SignUpTableViewController *viewController = [segue destinationViewController];
        [viewController setServer:self.server];
    }
}

@end
