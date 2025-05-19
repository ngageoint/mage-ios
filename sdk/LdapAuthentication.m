//
//  LdapAuthentication.m
//  mage-ios-sdk
//
//  Created by William Newman on 6/21/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LdapAuthentication.h"
#import "MageSessionManager.h"
#import "NSDate+Iso8601.h"
#import "CoreDataManager.h"
#import "StoredPassword.h"
#import "MAGE-Swift.h"

@interface LdapAuthentication()

@property (strong, nonatomic) NSDictionary* parameters;
@property (strong, nonatomic) NSDictionary* loginParameters;
@property (strong, nonatomic) NSDictionary *response;

@end

@implementation LdapAuthentication

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

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSDictionary *strategy = [parameters objectForKey:@"strategy"];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSString *url = [NSString stringWithFormat:@"%@/auth/%@/signin", [[MageServer baseURL] absoluteString], [strategy objectForKey:@"identifier"]];

    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        self.loginParameters = parameters;
        self.response = response;
        [self authorize:parameters complete:complete];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        // if the error was a network error try to login with the local auth module
        NSLog(@"Error logging in: %@", error);
        
        if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)) {
            NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
            // at this point, we might not have a connection to the server.
            complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
        } else {
            NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
            
            NSString* message;
            if (response.statusCode >= 500) {
                message = @"Cannot connect to server, please contact your MAGE administrator.";
            } else {
                message = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }
            
            if (!message) {
                message = @"Please check your username and password and try again.";
            }
            
            complete(AUTHENTICATION_ERROR, message);
        }
    }];
    
    [manager addTask:task];
}

- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString, NSString *errorDetail)) complete {
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
    
    [[CoreDataManager sharedManager] saveContext:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUser:userId context:localContext];
        if (!user) {
            [User insert:userJson context:localContext];
        } else {
            [user update:userJson context:localContext];
        }
    }];
    
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
    NSDictionary *strategy = [loginParameters objectForKey:@"strategy"];
    [defaults setValue:[strategy objectForKey:@"identifier"] forKey:@"loginType"];
    [defaults synchronize];
    [StoredPassword persistTokenToKeyChain:token];
    
    complete(AUTHENTICATION_SUCCESS, nil, nil);
}

- (void) authorize:(NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    // authentication succeeded, authorize with the mage server
    NSString *token = [self.response valueForKey:@"token"];
    NSDictionary *user = [self.response objectForKey:@"user"];
    
    // check if the user is active and if not but they have a user tell them to talk to a MAGE admin
    if (user && [[user objectForKey:@"active"] intValue] == 0) {
        return complete(ACCOUNT_CREATION_SUCCESS, @"Your account has been created.  Please contact your MAGE administrator to approve your account.");
    }
    
    NSDictionary *strategy = [parameters objectForKey:@"strategy"];
    
    NSMutableDictionary *authorizeParameters = [[NSMutableDictionary alloc] init];
    [authorizeParameters setObject:[parameters valueForKey:@"uid"] forKey:@"uid"];
    [authorizeParameters setObject:[strategy objectForKey:@"identifier"] forKey:@"strategy"];
    [authorizeParameters setObject:[parameters valueForKey:@"appVersion"] forKey:@"appVersion"];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSString *url = [NSString stringWithFormat:@"%@/auth/token", [[MageServer baseURL] absoluteString]];
        
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:authorizeParameters error:nil];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

            // if the error was a network error try to login with the local auth module
            if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNotConnectedToInternet)) {
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
        self.loginParameters = parameters;
        self.response = responseObject;
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
    
    [manager addTask:task];
}

@end
