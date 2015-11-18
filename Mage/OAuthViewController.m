//
//  OAuthViewController.m
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OAuthViewController.h"
#import <WebKit/WebKit.h>
#import "DeviceUUID.h"
#import "UserUtility.h"

@interface OAuthViewController()<WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *webView;
@end

@implementation OAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[WKWebView alloc] init];
    self.view = self.webView;
    self.webView.navigationDelegate = self;
    
    NSString *uidString = [DeviceUUID retrieveDeviceUUID].UUIDString;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?uid=%@", self.url, uidString]]]];
}

- (void)webView:(WKWebView *) webView didFinishNavigation:(WKNavigation *) navigation {    
    if ([webView.URL.path containsString:@"/callback"]) {
        [webView evaluateJavaScript:@"login" completionHandler:^(id result, NSError *error) {
            webView.hidden = YES;
            
            if (self.requestType == SIGNUP) {
                [self completeSignupWithResult:result];
            } else {
                [self completeSigninWithResult:result];
            }
        }];
    }
}

- (void) completeSignupWithResult: (NSDictionary *) result {
    id<Authentication> authentication = [Authentication authenticationModuleForType:self.authenticationType];
    NSDictionary* parameters = @{
                                 @"requestType": [NSNumber numberWithInt:SIGNUP],
                                 @"result": result
                                 };
    
    [authentication loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Account Creation Success"
                                  message:@"Your account has been successfully created.  An administrator must approve your account before you can login"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            
            [alert show];
            [self performSegueWithIdentifier:@"unwindToInitialSegue" sender:self];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Signup error"
                                  message:[result valueForKey:@"errorMessage"]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            
            [alert show];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void) completeSigninWithResult: (NSDictionary *) result {
    id<Authentication> authentication = [Authentication authenticationModuleForType:self.authenticationType];
    NSDictionary* parameters = @{
                                 @"requestType": [NSNumber numberWithInt:SIGNIN],
                                 @"result": result
                                 };
    
    [authentication loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
                [[UserUtility singleton] acceptConsent];
                [self performSegueWithIdentifier:@"SkipDisclaimerSegue" sender:nil];
            } else {
                [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
            }
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Registration Sent"
                                  message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            
            [alert show];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Signin Failed"
                                  message:[result valueForKey:@"errorMessage"]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            
            [alert show];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
