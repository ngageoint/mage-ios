//
//  ServerAuthentication.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/9/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ServerAuthentication.h"
#import "StoredPassword.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "User+helper.h"

@implementation ServerAuthentication

@synthesize delegate;

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (void) loginWithParameters: (NSDictionary *) parameters  {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    BOOL registered = [defaults boolForKey:@"deviceRegistered"];
    NSLog(@"registered? %d", registered);
    
    // if we think we need to register, go do it
    if (![defaults boolForKey:@"deviceRegistered"]) {
        NSLog(@"Not registered");
        [self registerDevice:parameters];
    } else {
        NSLog(@"Registered in theory, just log in");
        [self performLogin:parameters];
    }
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) performLogin: (NSDictionary *) parameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *username = (NSString *) [parameters objectForKey:@"username"];
    NSString *password = (NSString *) [parameters objectForKey:@"password"];
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/login"];
    
    [http.manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        NSString *token = [response objectForKey:@"token"];
        User *user = [self fetchUser:[response objectForKey:@"user"]];
        
        NSDateFormatter *dateFormat = [NSDateFormatter new];
        dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        // Always use this locale when parsing fixed format date strings
        NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormat.locale = posix;
        NSDate* tokenExpirationDate = [dateFormat dateFromString:[response objectForKey:@"expirationDate"]];
        
        [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
        [http.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
		      
        NSDictionary *loginParameters = @{
                                          @"username": username,
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"token": token,
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults synchronize];
        [StoredPassword persistPasswordToKeyChain:password];
        
        if (delegate) {
            [delegate authenticationWasSuccessful:user];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error logging in: %@", error);
        // try to register again
        [defaults setBool:NO forKey:@"deviceRegistered"];
        [self registerDevice:parameters];
    }];

}

- (void) registerDevice: (NSDictionary *) parameters {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/devices"];
    [http.manager POST: url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        BOOL registered = [[response objectForKey:@"registered"] boolValue];
        if (registered) {
            NSLog(@"Device was registered already, logging in");
            [defaults setBool:YES forKey:@"deviceRegistered"];
            // device was already registered, log in
            [self performLogin:parameters];
        } else {
            NSLog(@"Registration was successful");
            if (delegate) {
                [delegate registrationWasSuccessful];
            }
        }
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        if (delegate) {
            [delegate authenticationHadFailure];
        }
    }];
}

- (User *) fetchUser:(NSDictionary *) userJson {
    NSString *userId = [userJson objectForKey:@"_id"];
    User *user = [User fetchUserForId:userId];
    
    if (!user) {
        user = [User insertUserForJson:userJson myself:YES inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    return user;
}

@end
