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
@property (nonatomic) UIProgressView *progressView;
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

- (void) viewDidLoad {
    [super viewDidLoad];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.webView];
    self.webView.navigationDelegate = self;
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.center = self.view.center;
    [self.view addSubview:self.progressView];
    
    NSString *uidString = [DeviceUUID retrieveDeviceUUID].UUIDString;
    NSLog(@"Navigating to Oauth load %@", [NSString stringWithFormat:@"%@?uid=%@", self.url, uidString]);
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?uid=%@", self.url, uidString]]]];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void) viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webView) {
        [self.progressView setAlpha:1.0f];
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        
        if(self.webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"Redirect to %@", webView.URL.absoluteString);
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Failed navigation to %@", webView.URL.absoluteString);
    NSLog(@"Error: %@", error);
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Fail Provisional navigation to %@", webView.URL.absoluteString);
    NSLog(@"Error: %@", error);
}

- (void)webView:(WKWebView *) webView didFinishNavigation:(WKNavigation *) navigation {
    NSLog(@"Finished Navigation to %@", webView.URL.absoluteString);
    if ([webView.URL.path containsString:@"/callback"]) {
        NSLog(@"Logging in to MAGE");
        [webView evaluateJavaScript:@"login" completionHandler:^(id result, NSError *error) {
            webView.hidden = YES;
            
            [self.webView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
                NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                NSPredicate *cookiePredicate = [NSPredicate predicateWithFormat:@"SELF.name BEGINSWITH 'mage-'"];
                for (NSHTTPCookie *cookie in [cookies filteredArrayUsingPredicate:cookiePredicate]) {
                    [cookieStorage setCookie:cookie];
                }
                
                [self completeSigninWithResult:result];
            }];
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
