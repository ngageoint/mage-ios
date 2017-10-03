//
//  GoogleAuthentication.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GoogleAuthentication.h"
#import "User.h"
#import "MageSessionManager.h"
#import "UserUtility.h"
#import "NSDate+Iso8601.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"
#import "StoredPassword.h"

@interface GoogleAuthentication()

@property (strong, nonatomic) NSDictionary* parameters;

@end

@implementation GoogleAuthentication

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

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    [self signinWithParameters:[parameters valueForKey:@"user"] complete:complete];
}

- (void) signupWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSDictionary *user = [parameters objectForKey:@"user"];
    if (user != nil) {
        complete(AUTHENTICATION_SUCCESS, nil);
    } else {
        complete(AUTHENTICATION_ERROR, nil);
    }
}

- (void) signinWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"auth/google/signin"];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSLog(@"Logged in");
        
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
            [self finishLoginForParameters: parameters withResponse:response complete:complete];
        }];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error logging in: %@", error);
        // try to register again
        [defaults setBool:NO forKey:@"deviceRegistered"];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [self registerDevice:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
            if (authenticationStatus == AUTHENTICATION_ERROR) {
                complete(authenticationStatus, errResponse);
            } else {
                complete(authenticationStatus, errResponse);
            }
        }];
    }];
    
    [manager addTask:task];
}

- (void) finishLoginForParameters: (NSDictionary *) parameters withResponse: (NSDictionary *) response complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    
    NSString *token = [response objectForKey:@"token"];
    if (!token) {
        NSDictionary *device = [response objectForKey:@"device"];
        if (device != nil) {// && [device objectForKey:@"registered"]) {
            return complete(REGISTRATION_SUCCESS, nil);
        } else {
            return complete(AUTHENTICATION_ERROR, @"Device has not been registered");
        }
    }
    
    NSDictionary *userJson = [response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    if (currentUser != nil && ![currentUser.remoteId isEqualToString:userId]) {
        [MagicalRecord deleteAndSetupMageCoreDataStack];
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
        if (!user) {
            [User insertUserForJson:userJson inManagedObjectContext:localContext];
        } else {
            [user updateUserForJson:userJson];
        }
        
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[parameters objectForKey:@"expirationDate"]];
        [MageSessionManager manager].token = token;
        
        [[UserUtility singleton] resetExpiration];
        
        NSDictionary *loginParameters = @{
                                          @"token": [parameters objectForKey:@"token"],
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        [defaults setObject: userId forKey:@"currentUserId"];
        
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults synchronize];
        
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) registerDevice: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/devices"];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        BOOL registered = [[response objectForKey:@"registered"] boolValue];
        if (registered) {
            NSLog(@"Device was registered already, logging in");
            [defaults setBool:YES forKey:@"deviceRegistered"];
            // device was already registered, log in
            [self signinWithParameters:parameters complete:complete];
        } else {
            NSLog(@"Registration was successful");
            complete(REGISTRATION_SUCCESS, nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        complete(AUTHENTICATION_ERROR, errResponse);
    }];
    
    [manager addTask:task];
}


@end
