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
#import "NSDate+iso8601.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"
#import "StoredPassword.h"

@implementation OAuthAuthentication

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {    
    OAuthRequestType requestType = [[parameters valueForKey:@"requestType"] intValue];
    if (requestType == SIGNUP) {
        [self signupWithParameters:[parameters valueForKey:@"result"] complete:complete];
    } else {
        [self signinWithParameters:[parameters valueForKey:@"result"] complete:complete];
    }
}

- (void) signupWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    NSDictionary *user = [parameters objectForKey:@"user"];
    if (user != nil) {
        complete(AUTHENTICATION_SUCCESS);
    } else {
        complete(AUTHENTICATION_ERROR);
    }
}

- (void) signinWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
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
            MageSessionManager *manager = [MageSessionManager manager];
            
            [manager setToken:token];
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
            
            complete(AUTHENTICATION_SUCCESS);
        }];
    } else {
        NSDictionary *device = [parameters objectForKey:@"device"];
        if (device != nil && [device objectForKey:@"registered"]) {
            complete(REGISTRATION_SUCCESS);
        } else {
            complete(AUTHENTICATION_ERROR);
        }
    }
}

@end
