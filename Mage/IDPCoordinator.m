//
//  OAuthCoordinator.m
//  MAGE
//
//  Created by William Newman on 5/18/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "IDPCoordinator.h"
#import "DeviceUUID.h"

@interface IDPCoordinator ()
@property (weak, nonatomic) NSString *url;
@property (assign, nonatomic) NSDictionary *strategy;
@property (weak, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) SFSafariViewController *safariViewController;
@property (strong, nonatomic) id<LoginDelegate> delegate;
@end

@implementation IDPCoordinator

- (instancetype) initWithViewController: (UIViewController *) viewController url: (NSString *) url strategy: (NSDictionary *) strategy delegate: (id<LoginDelegate>) delegate {
    if (self = [super init]) {
        self.url = url;
        self.strategy = strategy;
        self.viewController = viewController;
        self.delegate = delegate;
    }
    
    return self;
}

- (void) start {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mageAppLinkNotification:) name:@"MageAppLink" object:nil];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?state=mobile", self.url]];
    self.safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    self.safariViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    self.safariViewController.delegate = self;
    self.safariViewController.presentationController.delegate = self;
    [self.viewController presentViewController:self.safariViewController animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self cleanup];
}

- (void) presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    [self cleanup];
}

- (void) cleanup {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MageAppLink" object:nil];
}

- (void) mageAppLinkNotification:(NSNotification *) notification {
    [self cleanup];

    NSURL *url = [notification object];
    
    if ([url.path containsString:@"authentication"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
        NSURLQueryItem *item = [[components.queryItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name=%@", @"token"]] firstObject];
        [self completeSignin:[item value]];
    } else {
        [self completeSignup];
    }
}

- (void) completeSignup {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Account Creation Success"
                                 message:@"Your account has been successfully created.  An administrator must approve your account before you can login"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self.safariViewController dismissViewControllerAnimated:YES completion:^{
        [self.viewController presentViewController:alert animated:YES completion:nil];
    }];
}

- (void) completeSignin:(NSString *) token {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey: @"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSDictionary* parameters = @{
                                 @"strategy": self.strategy,
                                 @"token": token,
                                 @"uid": [DeviceUUID retrieveDeviceUUID].UUIDString,
                                 @"appVersion": [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber]
                                 };
    
    [self.safariViewController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate loginWithParameters:parameters withAuthenticationStrategy:[self.strategy objectForKey:@"identifier"] complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        NSLog(@"Authentication complete %ld", (long)authenticationStatus);
    }];
}

@end
