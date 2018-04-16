//
//  GoogleAuthentication.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "OAuthAuthentication.h"
#import "User.h"
#import "MageSessionManager.h"
#import "UserUtility.h"
#import "NSDate+Iso8601.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"
#import "StoredPassword.h"

@interface OAuthAuthentication()

@property (strong, nonatomic) NSDictionary* parameters;
@property (strong, nonatomic) NSDictionary* loginParameters;
@property (strong, nonatomic) NSDictionary *response;

@end

@implementation OAuthAuthentication

- (instancetype) initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self == nil) return nil;
    
    self.parameters = parameters;
    
    return self;
}

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) loginWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    OAuthRequestType requestType = [[loginParameters valueForKey:@"requestType"] intValue];
    self.loginParameters = loginParameters;
    [self signinWithParameters:loginParameters complete:complete];
}

- (void) signupWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSDictionary *user = [parameters objectForKey:@"user"];
    if (user != nil) {
        complete(AUTHENTICATION_SUCCESS, nil);
    } else {
        complete(AUTHENTICATION_ERROR, nil);
    }
}

- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *api = [self.response objectForKey:@"api"];
    
    if ([api valueForKey:@"disclaimer"]) {
        [defaults setObject:[api valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
    }
    [defaults setObject:[api valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
    
    NSDictionary *userJson = [self.response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
        if (!user) {
            [User insertUserForJson:userJson inManagedObjectContext:localContext];
        } else {
            [user updateUserForJson:userJson];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSString *token = [self.response objectForKey:@"token"];
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[self.response objectForKey:@"expirationDate"]];
        
        [MageSessionManager manager].token = token;
        
        [[UserUtility singleton] resetExpiration];
        
        NSDictionary *loginParameters = @{
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        
        NSDictionary *userJson = [self.response objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        [defaults setObject: userId forKey:@"currentUserId"];
        
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults setBool:YES forKey:@"deviceRegistered"];
        [defaults setValue:[Authentication authenticationTypeToString:OAUTH2] forKey:@"loginType"];
        [defaults synchronize];
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) finishLoginForParameters: (NSDictionary *) parameters withResponse: (NSDictionary *) response complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *api = [response objectForKey:@"api"];
    
    if ([api objectForKey:@"disclaimer"] != NULL && [api valueForKey:@"disclaimer"]) {
        [defaults setObject:[api valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
    }
    [defaults setObject:[api valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
    
    NSDictionary *userJson = [response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
        if (!user) {
            [User insertUserForJson:userJson inManagedObjectContext:localContext];
        } else {
            [user updateUserForJson:userJson];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSString *token = [response objectForKey:@"token"];
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[response objectForKey:@"expirationDate"]];
        
        [MageSessionManager manager].token = token;
        
        [[UserUtility singleton] resetExpiration];
        
        NSDictionary *loginParameters = @{
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        
        NSDictionary *userJson = [response objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        [defaults setObject: userId forKey:@"currentUserId"];
        
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults setBool:YES forKey:@"deviceRegistered"];
        [defaults setValue:[Authentication authenticationTypeToString:OAUTH2] forKey:@"loginType"];
        [defaults synchronize];
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) registerDevice: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/auth/%@/devices", [[MageServer baseURL] absoluteString], [parameters valueForKey:@"strategy"]];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        BOOL registered = [[response objectForKey:@"registered"] boolValue];
        if (registered) {
            NSLog(@"Device was registered already, logging in");
            [defaults setBool:YES forKey:@"deviceRegistered"];
            // device was already registered, log in
            [self loginWithParameters:parameters complete:complete];
        } else {
            NSLog(@"Registration was successful");
            complete(REGISTRATION_SUCCESS, nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNotConnectedToInternet
                ))
        {
            NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
            // at this point, we might not have a connection to the server.
            complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
        } else {
            complete(AUTHENTICATION_ERROR, errResponse);
        }
    }];
    
    [manager addTask:task];
}

- (void) signinWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    
    NSDictionary *loginResult = [loginParameters valueForKey:@"result"];
    
    NSDictionary *oauth = [loginResult objectForKey:@"oauth"];
    if (!oauth) {
        return complete(AUTHENTICATION_ERROR, @"Login failed");
    }
    
    // check if the user is active and if not but they have a user tell them to talk to a MAGE admin
    
    // authentication succeeded, authorize with the mage server
    NSString *oauthToken = [oauth valueForKey:@"access_token"];
    NSDictionary *strategy = [loginParameters objectForKey:@"strategy"];
    
    NSMutableDictionary *authorizeParameters = [[NSMutableDictionary alloc] init];
    [authorizeParameters setObject:oauthToken forKey:@"access_token"];
    [authorizeParameters setObject:[loginParameters valueForKey:@"uid"] forKey:@"uid"];
    [authorizeParameters setObject:[strategy objectForKey:@"identifier"] forKey:@"strategy"];
    [authorizeParameters setObject:[loginParameters valueForKey:@"appVersion"] forKey:@"appVersion"];

    // make an authorize call to the MAGE server and then we will get a token back
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/auth/%@/authorize", [[MageServer baseURL] absoluteString], [strategy objectForKey:@"identifier"]];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:authorizeParameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSDictionary *api = [response objectForKey:@"api"];
        BOOL serverCompatible = [MageServer checkServerCompatibility:api];
        if (!serverCompatible) {
            NSError *error = [MageServer generateServerCompatibilityError:api];
            return complete(AUTHENTICATION_ERROR, error.localizedDescription);
        }
        self.loginParameters = loginParameters;
        self.response = response;
        [self finishLoginForParameters: loginParameters withResponse:response complete:complete];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        // if the error was a network error try to login with the local auth module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNotConnectedToInternet
                )) {
                NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
                // at this point, we might not have a connection to the server.
                complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
            } else {
                NSLog(@"Error logging in: %@", error);
                // try to register again
                [defaults setBool:NO forKey:@"deviceRegistered"];
                [self registerDevice:authorizeParameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
                    if (authenticationStatus == AUTHENTICATION_ERROR) {
                        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                        complete(authenticationStatus, errResponse);
                    } else {
                        complete(authenticationStatus, errorString);
                    }
                }];
            }
    }];
    
    [manager addTask:task];
}

@end
