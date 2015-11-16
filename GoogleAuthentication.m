//
//  GoogleAuthentication.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GoogleAuthentication.h"
#import "User+helper.h"
#import "HttpManager.h"
#import "UserUtility.h"
#import "NSDate+iso8601.h"
#import "MageServer.h"

@implementation GoogleAuthentication

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    
    NSString *token = [parameters valueForKey:@"token"];
    if (token != nil) {
        NSDictionary *userJson = [parameters objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
            if (!user) {
                user = [User insertUserForJson:userJson inManagedObjectContext:localContext];
            } else {
                [user updateUserForJson:userJson];
            }
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
            NSString *token = [parameters objectForKey:@"token"];
            
            // Always use this locale when parsing fixed format date strings
            NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[parameters objectForKey:@"expirationDate"]];
            HttpManager *http = [HttpManager singleton];
            
            [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [http.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [[UserUtility singleton] resetExpiration];
            
            NSDictionary *loginParameters = @{
                                              @"serverUrl": [[MageServer baseURL] absoluteString],
                                              @"token": token,
                                              @"tokenExpirationDate": tokenExpirationDate
                                              };
            
            [defaults setObject:loginParameters forKey:@"loginParameters"];
            [defaults setObject: userId forKey:@"currentUserId"];
            
            NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
            [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
            [defaults synchronize];
            
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
