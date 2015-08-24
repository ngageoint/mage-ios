//
//  ConsentViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/20/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DisclaimerViewController.h"
#import <UserUtility.h>

@interface DisclaimerViewController ()
@property (weak, nonatomic) IBOutlet UITextView *consentText;
@property (weak, nonatomic) IBOutlet UITextView *consentTitle;

@end

@implementation DisclaimerViewController

- (void) viewWillAppear:(BOOL)animated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.consentTitle setText:[defaults valueForKeyPath:@"disclaimerTitle"]];
    [self.consentText setText:[defaults valueForKeyPath:@"disclaimerText"]];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"AcceptConsentSegue"]) {
        [[UserUtility singleton ] acceptConsent];
    }
    return YES;
}

@end