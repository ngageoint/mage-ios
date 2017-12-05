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

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    OAuthRequestType requestType = [[parameters valueForKey:@"requestType"] intValue];
    if (requestType == SIGNUP) {
        [self signupWithParameters:[parameters valueForKey:@"result"] complete:complete];
    } else {
        [self signinWithParameters:[parameters valueForKey:@"result"] complete:complete];
    }
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
    NSString *token = [parameters valueForKey:@"token"];
    if (token != nil) {
        NSDictionary *userJson = [parameters objectForKey:@"user"];
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
    } else {
        NSDictionary *device = [parameters objectForKey:@"device"];
        if (device != nil && [device objectForKey:@"registered"]) {
            complete(REGISTRATION_SUCCESS, nil);
        } else {
            complete(AUTHENTICATION_ERROR, nil);
        }
    }
}

@end
