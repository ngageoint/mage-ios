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
#import "SignUpViewController_Server5.h"
#import "IDPLoginView.h"
#import "IDPCoordinator.h"
#import "DisclaimerViewController.h"
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "FadeTransitionSegue.h"
#import "MageSessionManager.h"
#import "DeviceUUID.h"
#import "AppDelegate.h"
#import "Authentication.h"
#import "UIColor+Hex.h"
#import "ContactInfo.h"
#import "MAGE-Swift.h"

@interface AuthenticationCoordinator() <LoginDelegate, DisclaimerDelegate, SignupDelegate, IDPButtonDelegate>

@property (weak, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MageServer *server;
@property (strong, nonatomic) NSString *signupUsername;
@property (strong, nonatomic) NSString *captchaToken;
@property (strong, nonatomic) NSDictionary *signupParameters;
@property (weak, nonatomic) id<AuthenticationDelegate> delegate;
@property (strong, nonatomic) LoginViewController *loginView;
@property (strong, nonatomic) IDPCoordinator *idpCoordinator;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation AuthenticationCoordinator

BOOL signingIn = YES;

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate:(id<AuthenticationDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme {
    self = [super init];
    if (!self) return nil;
    
    _scheme = containerScheme;
    _navigationController = navigationController;
    _delegate = delegate;
    
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

- (void) createAccount {
    signingIn = NO;
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    
    SignUpViewController *signupView;
    if ([MageServer isServerVersion5]) {
        signupView = [[SignUpViewController_Server5 alloc] initWithDelegate:self andScheme:self.scheme];
    } else {
        signupView = [[SignUpViewController alloc] initWithDelegate:self andScheme:self.scheme];
    }
    
    [self.navigationController pushViewController:signupView animated:NO];
}

- (void) getCaptcha:(NSString *) username completion:(void (^)(NSString* captcha)) completion  {
    NSString *background = [self.scheme.colorScheme.surfaceColor hex];
    
    self.signupUsername = username;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users/signups"]];
    NSDictionary *parameters = @{
                                 @"username": username,
                                 @"background": background
                                 };

    __weak typeof(self) weakSelf = self;
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [manager POST_TASK:[url absoluteString] parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        weakSelf.captchaToken =  [response objectForKey:@"token"];
        completion([response objectForKey:@"captcha"]);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Generating Captcha"
                                                                       message:errResponse
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];
}

- (void) signupWithParameters:(NSDictionary *) parameters completion:(void (^)(NSHTTPURLResponse *response)) completion  {
    __weak typeof(self) weakSelf = self;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users/signups/verifications"];
    
    NSLog(@"Parameters to sign up with %@", parameters);

    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:parameters error:nil];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.captchaToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        completion(httpResponse);
        
        if (error) {
            NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Account"
                                                                           message:errResponse
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
            });
            
            return;
        }
        
        NSString *username = [responseObject objectForKey:@"username"];
        NSString *displayName = [responseObject objectForKey:@"displayName"];
        NSString *isActive = [responseObject objectForKey:@"active"];
        NSString *msg = isActive.boolValue ? @"Your account is now active." : @"An administrator must approve your account before you can login";
      
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Created"
                                                                       message:[NSString stringWithFormat:@"%@ (%@) has been successfully created. %@", displayName, username, msg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Account Created";
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.navigationController popToViewController:self.loginView animated:NO];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];
}

- (void) signupCanceled {
    [self cancel];
}

- (void) captchaCanceled {
    [self cancel];
}

- (void) cancel {
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
    [MageServer serverWithUrl:url success:^(MageServer *mageServer) {
        [weakSelf showLoginViewForCurrentUserForServer:mageServer];
    } failure:^(NSError *error) {
        NSLog(@"failed to contact server");
    }];
}

- (void) start:(MageServer *) mageServer {
    [self showLoginViewForServer:mageServer];
}

- (void) showLoginViewForCurrentUserForServer: (MageServer *) mageServer {
    self.server = mageServer;
    User *currentUser = [User fetchCurrentUserWithContext:[NSManagedObjectContext MR_defaultContext]];
    self.loginView = [[LoginViewController alloc] initWithMageServer:mageServer andUser: currentUser andDelegate:self andScheme:_scheme];
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
    self.loginView = [[LoginViewController alloc] initWithMageServer:mageServer andDelegate:self andScheme:_scheme];
    [self.navigationController pushViewController:self.loginView animated:NO];
}

- (void) changeServerURL {
    [self.delegate changeServerUrl];
}

- (BOOL) didUserChange: (NSString *) username {
    User *currentUser = [User fetchCurrentUserWithContext:[NSManagedObjectContext MR_defaultContext]];
    return (currentUser != nil && ![currentUser.username isEqualToString:username]);
}

- (void) loginWithParameters:(NSDictionary *)parameters withAuthenticationStrategy:(NSString *) authenticationStrategy complete:(void (^)(AuthenticationStatus, NSString *))complete {
    id<AuthenticationProtocol> authenticationModule = [self.server.authenticationModules objectForKey:authenticationStrategy];
    if (!authenticationModule) {
        authenticationModule = [self.server.authenticationModules objectForKey:@"offline"];
    }
    
    if (!authenticationModule) {
        [self unableToAuthenticate: parameters complete:complete];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [authenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *message) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            if ([parameters objectForKey:@"username"] != NULL && [self didUserChange:[parameters objectForKey:@"username"]]) {
                if ([MageOfflineObservationManager offlineObservationCount] > 0) {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Loss of Unsaved Data"
                                                                                   message:@"The previously logged in user has unsaved observations.  Continuing with a new user will remove all previous data, including unsaved observations. Continue?"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    alert.accessibilityLabel = @"Loss of Unsaved Data";
                    [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [MageInitializer clearServerSpecificData];
                        [weakSelf authenticationWasSuccessfulWithModule:authenticationModule];
                    }]];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        NSLog(@"Do not delete the data");
                    }]];
                    
                    [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
                } else {
                    [MageInitializer clearServerSpecificData];
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
    alert.accessibilityLabel = @"MAGE Account Created";
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void) failedToAuthenticate:(NSString *) message {
    NSString *error = [message isEqualToString:@"Unauthorized"] ? @"The username or password you entered is incorrect" : message;
    
    ContactInfo * info = [[ContactInfo alloc] initWithTitle:@"Login Failed" andMessage:error];
            
    [self.loginView  setContactInfo:info];
}

- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // if the user has already logged in offline just tell them
    if ([@"offline" isEqualToString:[defaults valueForKey:@"loginType"]]) {
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
    id <AuthenticationProtocol> offlineAuthenticationModel = [self.server.authenticationModules objectForKey:@"offline"];
    if (offlineAuthenticationModel) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Disconnected Login"
                                                                       message:@"We are unable to connect to the server. Would you like to work offline until a connection to the server can be established?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Disconnected Login";
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
        alert.accessibilityLabel = @"Unable to Login";
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf returnToLogin: complete];
        }]];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    __weak typeof(self) weakSelf = self;

    NSLog(@"work offline");
    id<AuthenticationProtocol> offlineAuthenticationModel = [self.server.authenticationModules objectForKey:@"offline"];
    if (!offlineAuthenticationModel) {
        [weakSelf unableToAuthenticate: parameters complete:complete];
        return;
    }
    
    [offlineAuthenticationModel loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessfulWithModule:offlineAuthenticationModel];
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

- (void) authenticationWasSuccessfulWithModule: (id<AuthenticationProtocol>) module {
    
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
                [viewController applyThemeWithContainerScheme:self.scheme];
                [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
                
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self.navigationController pushViewController:viewController animated:NO];
            }
        }
    }];
}

- (void) registrationWasSuccessful {
    NSString * error =@"Your device has been registered.  \nAn administrator has been notified to approve this device.";
    
    ContactInfo * info = [[ContactInfo alloc] initWithTitle:@"Registration Sent" andMessage:error];
    
    [self.loginView  setContactInfo:info];
    
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
