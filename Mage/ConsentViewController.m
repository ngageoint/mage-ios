//
//  ConsentViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/20/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ConsentViewController.h"
#import <UserUtility.h>

@interface ConsentViewController ()

@end

@implementation ConsentViewController

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"AcceptConsentSegue"]) {
        [[UserUtility singleton ] acceptConsent];
    }
    return YES;
}

@end
