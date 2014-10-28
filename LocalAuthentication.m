//
//  LocalAuthentication.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocalAuthentication.h"

#import <AFNetworking/AFNetworking.h>

#import "User+helper.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation LocalAuthentication

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

- (void) performLogin: (NSDictionary *) parameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
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
		      
        NSDictionary *loginParameters = @{
          @"username": (NSString *) [parameters objectForKey:@"username"],
          @"serverUrl": [[MageServer baseURL] absoluteString],
          @"token": token,
          @"tokenExpirationDate": tokenExpirationDate
        };
    
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        [defaults synchronize];
        
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
		user = [User insertUserForJson:userJson myself:YES];
	}
		
	return user;
}

@end