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
@property (strong, nonatomic) id<LoginDelegate> delegate;
@end

@implementation OAuthViewController

- (instancetype) initWithUrl: (NSString *) url andAuthenticationType: (AuthenticationType) authenticationType andRequestType: (OAuthRequestType) requestType andStrategy:(NSDictionary *)strategy andLoginDelegate:(id<LoginDelegate>)delegate {
    if (self = [super init]) {
        self.url = url;
        self.authenticationType = authenticationType;
        self.requestType = requestType;
        self.strategy = strategy;
        self.delegate = delegate;
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
            
//            if (self.requestType == SIGNUP) {
//                [self completeSignupWithResult:result];
//            } else {
                [self completeSigninWithResult:result];
//            }
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
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];

    NSString *appVersion = [infoDict objectForKey: @"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSDictionary* parameters = @{
                                 @"strategy": self.strategy,
                                 @"requestType": [NSNumber numberWithInt:SIGNIN],
                                 @"result": result,
                                 @"uid": [DeviceUUID retrieveDeviceUUID].UUIDString,
                                 @"appVersion": [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber]
                                 };
    [self.delegate loginWithParameters:parameters withAuthenticationType:self.authenticationType complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        NSLog(@"Authentication complete %ld", (long)authenticationStatus);
    }];
}

@end
