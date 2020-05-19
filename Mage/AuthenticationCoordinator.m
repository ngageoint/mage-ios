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
#import "IDPLoginView.h"
#import "IDPCoordinator.h"
#import "DisclaimerViewController.h"
#import "MageServer.h"
#import "Server.h"
#import "MageOfflineObservationManager.h"
#import "MagicalRecord+MAGE.h"
#import "UserUtility.h"
#import "FadeTransitionSegue.h"
#import "ServerURLController.h"
#import "MageSessionManager.h"
#import "DeviceUUID.h"
#import "AppDelegate.h"
#import "Authentication.h"

@interface AuthenticationCoordinator() <LoginDelegate, DisclaimerDelegate, ServerURLDelegate, SignUpDelegate, IDPButtonDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MageServer *server;
@property (strong, nonatomic) id<AuthenticationDelegate> delegate;
@property (strong, nonatomic) LoginViewController *loginView;
@property (strong, nonatomic) ServerURLController *urlController;
@property (strong, nonatomic) IDPCoordinator *idpCoordinator;

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

- (void) createAccount {
    signingIn = NO;
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    SignUpViewController *signupView = [[SignUpViewController alloc] initWithServer:self.server andDelegate:self];
    [self.navigationController pushViewController:signupView animated:NO];
}

- (void) signUpWithParameters:(NSDictionary *)parameters atURL:(NSURL *)url {
    __weak typeof(self) weakSelf = self;
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager POST_TASK:[url absoluteString] parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSString *username = [response objectForKey:@"username"];
        NSString *displayName = [response objectForKey:@"displayName"];
        NSString *isActive = [response objectForKey:@"active"];
        NSString *msg = isActive.boolValue ? @"Your account is now active." : @"An administrator must approve your account before you can login";
      
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Created"
                                                                       message:[NSString stringWithFormat:@"%@ (%@) has been successfully created. %@", displayName, username, msg]
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

- (void) signinForStrategy:(NSDictionary *)strategy {
    NSString *url = [NSString stringWithFormat:@"%@/auth/%@/signin", [[MageServer baseURL] absoluteString], [strategy objectForKey:@"identifier"]];
    
    self.idpCoordinator = [[IDPCoordinator alloc] initWithViewController:self.navigationController url:url strategy:strategy delegate:self];
    [self.idpCoordinator start];
}

- (void) startLoginOnly {
    NSURL *url = [MageServer baseURL];
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        [weakSelf showLoginViewForCurrentUserForServer:mageServer];
    } failure:^(NSError *error) {
        NSLog(@"failed to contact server");
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
            [weakSelf showLoginViewForServer:mageServer];
        } failure:^(NSError *error) {
            [weakSelf changeServerURLWithError: error.localizedDescription];
        }];
    }
}

- (void) showLoginViewForCurrentUserForServer: (MageServer *) mageServer {
    self.server = mageServer;
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    self.loginView = [[LoginViewController alloc] initWithMageServer:mageServer andUser: currentUser andDelegate:self];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.loginView animated:NO];
}

- (void) showLoginViewForServer: (MageServer *) mageServer {
    signingIn = YES;
    self.server = mageServer;
    // If the user is logging in, force them to pick the event again
    [Server removeCurrentEventId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"loginType"];
    [defaults synchronize];
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"baseServerUrl"];
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

- (void) loginWithParameters:(NSDictionary *)parameters withAuthenticationType:(AuthenticationType)authenticationType complete:(void (^)(AuthenticationStatus, NSString *))complete {
    id<Authentication> authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:authenticationType]];
    if (!authenticationModule) {
        authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [authenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *message) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            if ([parameters objectForKey:@"username"] != NULL && [self didUserChange:[parameters objectForKey:@"username"]]) {
                if ([MageOfflineObservationManager offlineObservationCount] > 0) {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Loss of Unsaved Data"
                                                                                   message:@"The previously logged in user has unsaved observations.  Continuing with a new user will remove all previous data, including unsaved observations. Continue?"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [MagicalRecord deleteAndSetupMageCoreDataStack];
                        [weakSelf authenticationWasSuccessfulWithModule:authenticationModule];
                    }]];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        NSLog(@"Do not delete the data");
                    }]];
                    
                    [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
                } else {
                    [MagicalRecord deleteAndSetupMageCoreDataStack];
                    [weakSelf authenticationWasSuccessfulWithModule:authenticationModule];
                }
                
            } else {
                [weakSelf authenticationWasSuccessfulWithModule:authenticationModule];
            }
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else if (authenticationStatus == AUTHENTICATION_ERROR) {
            [weakSelf failedToAuthenticate:message];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf unableToAuthenticate: parameters complete:complete];
            return;
        } else if (authenticationStatus == ACCOUNT_CREATION_SUCCESS) {
            [weakSelf accountCreationSuccess:parameters];
        }
        complete(authenticationStatus, message);
    }];
}

- (void) accountCreationSuccess: (NSDictionary *) parameters {
    [self.navigationController popToViewController:self.loginView animated:NO];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"MAGE Account Created"
                                                                   message:@"Account created, please contact your MAGE administrator to activate your account."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void) failedToAuthenticate:(NSString *) message {
    NSString *error = [message isEqualToString:@"Unauthorized"] ? @"The username or password you entered is incorrect" : message;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed"
                                                                   message:error
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // if the user has already logged in offline just tell them
    if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Disconnected Login"
                                    message:@"We are still unable to connect to the server to log you in. You will continue to work offline."
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.delegate couldNotAuthenticate];
            complete(AUTHENTICATION_SUCCESS, nil);
        }]];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // If there is a stored password do this
    id <Authentication> localAuthenticationModel = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    if (localAuthenticationModel) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Disconnected Login"
                                                                       message:@"We are unable to connect to the server. Would you like to work offline until a connection to the server can be established?"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"OK, Work Offline" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf workOffline: parameters complete:complete];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Return to Login" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf returnToLogin: complete];
        }]];

        [self.navigationController presentViewController:alert animated:YES completion:nil];
    } else {
        // there is no stored password for this server
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Unable to Login" message:@"We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf returnToLogin: complete];
        }]];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;

    NSLog(@"work offline");
    id<Authentication> localAuthenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    [localAuthenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessfulWithModule:localAuthenticationModule];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf unableToAuthenticate: parameters complete:complete];
            return;
        }
        complete(authenticationStatus, errorString);
    }];
}

- (void) returnToLogin: (void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    complete(UNABLE_TO_AUTHENTICATE, @"We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored.");
}

- (void) authenticationWasSuccessfulWithModule: (id<Authentication>) module {
    
    [module finishLogin:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
                [self disclaimerAgree];
                NSLog(@"Skip the disclaimer screen");
            } else {
                NSLog(@"Segue to the disclaimer screen");
                DisclaimerViewController *viewController = [[DisclaimerViewController alloc] initWithNibName:@"DisclaimerConsent" bundle:nil];
                viewController.delegate = self;
                [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
                
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self.navigationController pushViewController:viewController animated:NO];
            }
        }
    }];
}

- (void) registrationWasSuccessful {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Registration Sent"
                                 message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    if (![[self.navigationController topViewController] isKindOfClass:[LoginViewController class]]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
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
