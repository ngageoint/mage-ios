//
//  IdpAuthentication.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "IdpAuthentication.h"
#import "MageSessionManager.h"
#import "NSDate+Iso8601.h"
#import "MagicalRecord+MAGE.h"
#import "StoredPassword.h"
#import "MAGE-Swift.h"
#import <AFNetworking/AFNetworking.h>

@interface IdpAuthentication()

@property (strong, nonatomic) NSDictionary* parameters;
@property (strong, nonatomic) NSDictionary* loginParameters;
@property (strong, nonatomic) NSDictionary *response;

@end

@implementation IdpAuthentication

- (instancetype) initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self == nil) return nil;
    
    self.parameters = parameters;
    
    return self;
}

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) loginWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    self.loginParameters = loginParameters;
    [self authorize:loginParameters complete:complete];
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
    NSDictionary *contactinfo = [api valueForKey:@"contactinfo"];
    if (contactinfo) {
        [defaults setObject:[contactinfo valueForKeyPath:@"email"] forKey:@"contactInfoEmail"];
        [defaults setObject:[contactinfo valueForKeyPath:@"phone"] forKey:@"contactInfoPhone"];
    }
    [defaults setObject:[api valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
    
    NSDictionary *userJson = [self.response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserWithUserId:userId context:localContext];
        if (!user) {
            [User insertWithJson:userJson context:localContext];
        } else {
            [user updateWithJson:userJson context:localContext];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSString *token = [self.response objectForKey:@"token"];
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[self.response objectForKey:@"expirationDate"]];
        
        [MageSessionManager sharedManager].token = token;
        
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
        [defaults setValue:[self.parameters objectForKey:@"type"] forKey:@"loginType"];
        [defaults synchronize];
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) registerDevice: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    MageSessionManager *manager = [MageSessionManager sharedManager];
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

- (void) authorize: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSString *token = [loginParameters valueForKey:@"token"];
    NSDictionary *strategy = [loginParameters objectForKey:@"strategy"];
    
    NSMutableDictionary *authorizeParameters = [[NSMutableDictionary alloc] init];
    [authorizeParameters setObject:[loginParameters valueForKey:@"uid"] forKey:@"uid"];
    [authorizeParameters setObject:[strategy objectForKey:@"identifier"] forKey:@"strategy"];
    [authorizeParameters setObject:[loginParameters valueForKey:@"appVersion"] forKey:@"appVersion"];

    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSString *url = [NSString stringWithFormat:@"%@/auth/token", [[MageServer baseURL] absoluteString]];
        
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:authorizeParameters error:nil];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

            // if the error was a network error try to login with the local auth module
            if ([error.domain isEqualToString:NSURLErrorDomain]&& (error.code == NSURLErrorCannotConnectToHost|| error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)) {
                NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
                // at this point, we might not have a connection to the server.
                complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
            } else if (httpResponse.statusCode == 403) {
                NSLog(@"Error authorizing device uid in: %@", error);
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:NO forKey:@"deviceRegistered"];
                NSString* message = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                complete(REGISTRATION_SUCCESS, message);
            } else {
                NSString* message = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                complete(AUTHENTICATION_ERROR, message);
            }
            
            return;
        }
        
        NSDictionary *api = [responseObject objectForKey:@"api"];
        BOOL serverCompatible = [MageServer checkServerCompatibilityWithApi:api];
        if (!serverCompatible) {
            NSError *error = [MageServer generateServerCompatibilityErrorWithApi:api];
            return complete(AUTHENTICATION_ERROR, error.localizedDescription);
        }
        self.loginParameters = loginParameters;
        self.response = responseObject;
        complete(AUTHENTICATION_SUCCESS, nil);
    }];

    [manager addTask:task];
}

@end
