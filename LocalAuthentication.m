//
//  LocalAuthentication.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocalAuthentication.h"

#import <AFNetworking/AFNetworking.h>

#import "User.h"
#import "HttpManager.h"

@implementation LocalAuthentication

@synthesize delegate;

//AFHTTPSessionManager *manager;

- (id) initWithURL: (NSURL *) url {
	if (self = [super init]) {
		_baseURL = url;
		
		//manager = [self createHTTPSessionManager:_baseURL];
	}
	
	return self;
}

- (void) loginWithParameters: (NSDictionary *) parameters {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [_baseURL absoluteString], @"api/login"];
    

    HttpManager *http = [HttpManager singleton];

    [http.manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        User *user = [[User alloc] initWithJSON:responseObject];
        
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [defaults setObject: user.token forKey:@"token"];
        [defaults synchronize];
        
        
        [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", user.token] forHTTPHeaderField:@"Authorization"];
		
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

//- (AFHTTPSessionManager *) createHTTPSessionManager: (NSURL *) url {
//	AFHTTPSessionManager *m = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
//	m.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
//	m.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONReadingAllowFragments];
//	
//	return m;
//}

@end