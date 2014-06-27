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

@interface LocalAuthentication ()
	@property(nonatomic) NSManagedObjectContext *context;
@end

@implementation LocalAuthentication

@synthesize delegate;

- (id) initWithURL: (NSURL *) url inManagedObjectContext:(NSManagedObjectContext *) context {
	if (self = [super init]) {
		_baseURL = url;
		_context = context;
	}
	
	return self;
}

- (void) loginWithParameters: (NSDictionary *) parameters {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [_baseURL absoluteString], @"api/login"];
    

    HttpManager *http = [HttpManager singleton];

    [http.manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        NSString *token = [response objectForKey:@"token"];
		User *user = [self fetchUser:[response objectForKey:@"user"]];
		
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [defaults setObject: token forKey:@"token"];
        [defaults synchronize];
        
        [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
		
		if (delegate) {
			[delegate authenticationWasSuccessful:user];
		}
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        if (delegate) {
			[delegate authenticationHadFailure];
		}
    }];
}

- (User *) fetchUser:(NSDictionary *) userJson {
	NSString *userId = [userJson objectForKey:@"_id"];
	User *user = [User fetchUserForId:userId inManagedObjectContext:_context];
	
	if (!user) {
		user = [User insertUserForJson:userJson inManagedObjectContext:_context];
	}
		
	return user;
}

@end