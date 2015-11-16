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
            
            id<Authentication> authentication = [Authentication authenticationModuleForType:GOOGLE];
            [authentication loginWithParameters:result complete:^(AuthenticationStatus authenticationStatus) {
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
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }];
        }];
    }
}

@end
