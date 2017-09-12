//
//  AuthenticationCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/6/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AuthenticationCoordinator.h"
#import "LoginViewController.h"
#import "DisclaimerViewController.h"
#import <MageServer.h>
#import "Server.h"
#import "MageOfflineObservationManager.h"
#import "MagicalRecord+MAGE.h"
#import <UserUtility.h>
#import "FadeTransitionSegue.h"
#import "ServerURLController.h"

@interface AuthenticationCoordinator() <LoginDelegate, DisclaimerDelegate, ServerURLDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MageServer *server;
@property (strong, nonatomic) id<AuthenticationDelegate> delegate;
@property (strong, nonatomic) LoginViewController *loginView;
@property (strong, nonatomic) ServerURLController *urlController;

@end

@implementation AuthenticationCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate:(id<AuthenticationDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    _navigationController = navigationController;
    _delegate = delegate;
    
    return self;
}

- (void) start {
    NSURL *url = [MageServer baseURL];
    if ([url absoluteString].length == 0) {
        [self changeServerURL];
        return;
    } else {
        NSURL *url = [MageServer baseURL];
        __weak __typeof__(self) weakSelf = self;
        [MageServer serverWithURL:url success:^(MageServer *mageServer) {
            [weakSelf showLoginViewForServer:mageServer];
         } failure:^(NSError *error) {
             [weakSelf.urlController showError:error.localizedDescription];
         }];
    }
    
}

- (void) showLoginViewForServer: (MageServer *) mageServer {
    self.server = mageServer;
    // If the user is logging in, force them to pick the event again
    [Server removeCurrentEventId];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    self.loginView = [[LoginViewController alloc] initWithMageServer:mageServer andDelegate:self];
    [self.navigationController pushViewController:self.loginView animated:NO];
}

- (void) changeServerURL {
    self.urlController = [[ServerURLController alloc] initWithDelegate:self];
    [self.navigationController presentViewController:self.urlController animated:YES completion:nil];
}

- (void) cancelSetServerURL {
    [self.urlController dismissViewControllerAnimated:YES completion:nil];
}

- (void) setServerURL:(NSURL *)url {
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        [MagicalRecord deleteAndSetupMageCoreDataStack];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.urlController dismissViewControllerAnimated:YES completion:nil];
            [weakSelf showLoginViewForServer:mageServer];
        });
    } failure:^(NSError *error) {
        [weakSelf.urlController showError:error.localizedDescription];
    }];
}


- (BOOL) didUserChange: (NSString *) username {
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    return (currentUser != nil && ![currentUser.username isEqualToString:username]);
}

- (void) loginWithParameters:(NSDictionary *)parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    
    if (self.server.reachabilityManager.reachable && [self didUserChange:[parameters objectForKey:@"username"]]) {
        if ([MageOfflineObservationManager offlineObservationCount] > 0) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Loss of Unsaved Data"
                                                                           message:@"The previously logged in user has unsaved observations.  Continuing with a new user will remove all previous data, including unsaved observations. Continue?"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            __weak __typeof__(self) weakSelf = self;
            [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [MagicalRecord deleteAndSetupMageCoreDataStack];
                [weakSelf doLogin:parameters complete:complete];
                
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:alert animated:NO completion:nil];
        } else {
            [MagicalRecord deleteAndSetupMageCoreDataStack];
            [self doLogin:parameters complete:complete];
        }
        
    } else {
        [self doLogin:parameters complete:complete];
    }
}

- (void) doLogin:(NSDictionary *)parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    id<Authentication> authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
    if (!authenticationModule) {
        authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [authenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else {
            [weakSelf authenticationHadFailure];
        }
        complete(authenticationStatus);
    }];
}

- (void) authenticationWasSuccessful {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
        [self disclaimerAgree];
        NSLog(@"Skip the disclaimer screen");
    } else {
        NSLog(@"Segue to the disclaimer screen");
        DisclaimerViewController *disclaimer = [[DisclaimerViewController alloc] initWithDelegate:self];
        [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];

        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController pushViewController:disclaimer animated:NO];
    }

}

- (void) authenticationHadFailure {
//    [self.loginView authenticationHadFailure];
//    self.statusButton.hidden = NO;
//    self.loginStatus.hidden = NO;
//    
//    self.loginStatus.text = @"The username or password you entered is incorrect";
//    self.usernameField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
//    self.passwordField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
//    
//    self.loginFailure = YES;
//    [self endLogin];
}

- (void) registrationWasSuccessful {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Registration Sent"
                                 message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
    
}

- (void) disclaimerDisagree {
    
}

- (void) disclaimerAgree {
    [[UserUtility singleton] acceptConsent];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.delegate authenticationSuccessful];
}

@end
