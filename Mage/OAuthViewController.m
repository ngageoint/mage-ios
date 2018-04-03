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

- (instancetype) initWithUrl: (NSString *) url andAuthenticationType: (AuthenticationType) authenticationType andRequestType: (OAuthRequestType) requestType {
    if (self = [super init]) {
        self.url = url;
        self.authenticationType = authenticationType;
        self.requestType = requestType;
    }
    return self;
}

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
    __weak typeof(self) weakSelf = self;
    [authentication loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Account Creation Success"
                                         message:@"Your account has been successfully created.  An administrator must approve your account before you can login"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf performSegueWithIdentifier:@"unwindToInitialSegue" sender:self];
            }]];
            
            [weakSelf presentViewController:alert animated:YES completion:nil];            
        } else {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Signup error"
                                         message:[result valueForKey:@"errorMessage"]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void) completeSigninWithResult: (NSDictionary *) result {
    id<Authentication> authentication = [Authentication authenticationModuleForType:self.authenticationType];
    NSDictionary* parameters = @{
                                 @"requestType": [NSNumber numberWithInt:SIGNIN],
                                 @"result": result
                                 };
    
    __weak typeof(self) weakSelf = self;
    [authentication loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
                [[UserUtility singleton] acceptConsent];
                [self performSegueWithIdentifier:@"SkipDisclaimerSegue" sender:nil];
            } else {
                [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
            }
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Registration Sent"
                                         message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [weakSelf presentViewController:alert animated:YES completion:nil];
            
        } else {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Signin Failed"
                                         message:[result valueForKey:@"errorMessage"]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }
    }];
}

@end
