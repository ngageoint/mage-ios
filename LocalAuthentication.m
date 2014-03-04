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

@implementation LocalAuthentication

- (id) initWithURL: (NSURL *) baseURL andParameters: (NSDictionary *) parameters {
	if (self = [super init]) {
		_baseURL = baseURL;
		_parameters = parameters;
	}
	
	return self;
}

- (void) login {
	NSString *username = [_parameters objectForKey:@"username"];
	NSString *password = [_parameters objectForKey:@"password"];
	NSString *uid = [_parameters objectForKey:@"uid"];
	
	NSDictionary *parameters = @{@"username": username, @"password": password, @"uid": uid};
  
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
	manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONReadingAllowFragments];
	
	NSString *url = [NSString stringWithFormat:@"%@/%@", [_baseURL absoluteString], @"api/login"];
	[manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		User *user = [[User alloc] initWithJSON:responseObject];
		
		if (_delegate) {
			[_delegate loginSuccess:user];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (_delegate) {
			[_delegate loginFailure];
		}
	}];
}



@end
