//
//  AuthenticationCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/6/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AuthenticationCoordinator.h"
#import "LoginViewController.h"
#import "SignUpViewController.h"
#import "GoogleSignUpViewController.h"
#import "DisclaimerViewController.h"
#import <MageServer.h>
#import "Server.h"
#import "MageOfflineObservationManager.h"
#import "MagicalRecord+MAGE.h"
#import <UserUtility.h>
#import "FadeTransitionSegue.h"
#import "ServerURLController.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import "GoogleAuthentication.h"
#import <MageSessionManager.h>
#import "DeviceUUID.h"
#import "AppDelegate.h"

@interface AuthenticationCoordinator() <LoginDelegate, DisclaimerDelegate, ServerURLDelegate, GIDSignInDelegate, SignUpDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MageServer *server;
@property (strong, nonatomic) id<AuthenticationDelegate> delegate;
@property (strong, nonatomic) LoginViewController *loginView;
@property (strong, nonatomic) ServerURLController *urlController;

@end

@implementation AuthenticationCoordinator

BOOL signingIn = YES;

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate:(id<AuthenticationDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    _navigationController = navigationController;
    _delegate = delegate;
    
    return self;
}

/**
 In order to use Google sign in, you must download a GoogleService-Info plist file and add the url scheme to the app.
 Follow the instructions here: https://developers.google.com/identity/sign-in/ios/start-integrating
 
 After this is done, add the client id to your server google configuration
 "google": {
 "clientID":[<web client ID>, <iOS clientID>, <Android client ID>],
 "webClientID": "<client ID for the web client>"
 }
 */
- (void) setupGoogleSignIn {
    NSString *path = [[NSBundle mainBundle] pathForResource: @"GoogleService-Info" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    [GIDSignIn sharedInstance].clientID = [dict objectForKey: @"CLIENT_ID"];
    [GIDSignIn sharedInstance].delegate = self;
}

- (void) createAccount {
    [self showSignupView];
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (signingIn) {
        [self completeGoogleSigninWithUser:user];
    } else {
        [self completeGoogleSignUpWithUser:user];
    }
}

- (void) signUpWithParameters:(NSDictionary *)parameters atURL:(NSURL *)url {
    __weak typeof(self) weakSelf = self;
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager POST_TASK:[url absoluteString] parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSString *username = [response objectForKey:@"username"];
        NSString *displayName = [response objectForKey:@"displayName"];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Created"
                                                                       message:[NSString stringWithFormat:@"%@ (%@) has been successfully created.  An administrator must approve your account before you can login", displayName, username]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.navigationController popToViewController:self.loginView animated:NO];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Account"
                                                                       message:errResponse
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];

}

- (void) signUpCanceled {
    signingIn = YES;
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController popToViewController:self.loginView animated:NO];
}

- (void) completeGoogleSignUpWithUser: (GIDGoogleUser *) user {
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    GoogleSignUpViewController *signupView = [[GoogleSignUpViewController alloc] initWithServer:self.server andGoogleUser:user andDelegate:self];
    [self.navigationController pushViewController:signupView animated:NO];
}

- (void) completeGoogleSigninWithUser: (GIDGoogleUser *) user {
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
    NSString *uidString = deviceUUID.UUIDString;
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:user.authentication.idToken forKey:@"token"];
    [userDictionary setObject:user.userID forKey:@"userID"];
    [userDictionary setObject:user.profile.name forKey:@"displayName"];
    [userDictionary setObject:user.profile.email forKey:@"email"];
    [userDictionary setObject:uidString forKey:@"uid"];
    id<Authentication> authentication = [Authentication authenticationModuleForType:GOOGLE];
    NSDictionary* parameters = @{
                                 @"user": userDictionary
                                 };
    
    __weak typeof(self) weakSelf = self;
    [authentication loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
            [[GIDSignIn sharedInstance] signOut];
        } else {
            [weakSelf authenticationHadFailure: errorString];
            [[GIDSignIn sharedInstance] signOut];
        }
    }];
}

- (void) start {
    NSURL *url = [MageServer baseURL];
    if ([url absoluteString].length == 0) {
        [self changeServerURL];
        return;
    } else {
        __weak __typeof__(self) weakSelf = self;
        [MageServer serverWithURL:url success:^(MageServer *mageServer) {
            if (mageServer.serverHasGoogleAuthenticationStrategy) {
                [self setupGoogleSignIn];
            }
            [weakSelf showLoginViewForServer:mageServer];
        } failure:^(NSError *error) {
            [weakSelf changeServerURLWithError: error.localizedDescription];
        }];
    }
}

- (void) showSignupView {
    [[GIDSignIn sharedInstance] signOut];
    signingIn = NO;
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    SignUpViewController *signupView = [[SignUpViewController alloc] initWithServer:self.server andDelegate:self];
    [self.navigationController pushViewController:signupView animated:NO];
}

- (void) showLoginViewForServer: (MageServer *) mageServer {
    signingIn = YES;
    self.server = mageServer;
    [[GIDSignIn sharedInstance] signOut];
    // If the user is logging in, force them to pick the event again
    [Server removeCurrentEventId];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    self.loginView = [[LoginViewController alloc] initWithMageServer:mageServer andDelegate:self];
    [self.navigationController pushViewController:self.loginView animated:NO];
}

- (void) changeServerURLWithError: (NSString *) error {
    self.urlController = [[ServerURLController alloc] initWithDelegate:self andError: error];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) changeServerURL {
    self.urlController = [[ServerURLController alloc] initWithDelegate:self];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) cancelSetServerURL {
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void) setServerURL:(NSURL *)url {
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        [MagicalRecord deleteAndSetupMageCoreDataStack];
        dispatch_async(dispatch_get_main_queue(), ^{
            [FadeTransitionSegue addFadeTransitionToView:weakSelf.navigationController.view];
            [weakSelf.navigationController popViewControllerAnimated:NO];
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

- (void) loginWithParameters:(NSDictionary *)parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    
    if ([self didUserChange:[parameters objectForKey:@"username"]]) {
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

- (void) doLogin:(NSDictionary *)parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    id<Authentication> authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
    if (!authenticationModule) {
        authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [authenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf unableToAuthenticate: parameters complete:complete];
            return;
        } else {
            [weakSelf authenticationHadFailure:errorString];
        }
        complete(authenticationStatus, errorString);
    }];
}

- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;

    // If there is a stored password do this
    id <Authentication> localAuthenticationModel = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    if (localAuthenticationModel) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Disconnected Login"
                                     message:@"We are unable to connect to the server. Would you like to work offline until a connection to the server can be established?"
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"OK, Work Offline" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf workOffline: parameters complete:complete];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Try Login Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf tryLoginAgain];
        }]];

        [self.navigationController presentViewController:alert animated:YES completion:nil];
    } else {
    
    }
}

- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;

    NSLog(@"work offline");
    id<Authentication> localAuthenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    [localAuthenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf unableToAuthenticate: parameters complete:complete];
            return;
        } else {
            [weakSelf authenticationHadFailure:errorString];
        }
        complete(authenticationStatus, errorString);
    }];
}

- (void) tryLoginAgain {
    
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

- (void) authenticationHadFailure: (NSString *) errorString {
    [self.loginView authenticationHadFailure:errorString];
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
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate logout];
}

- (void) disclaimerAgree {
    [[UserUtility singleton] acceptConsent];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.delegate authenticationSuccessful];
}

@end
