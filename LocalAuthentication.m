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

@synthesize delegate;

AFHTTPSessionManager *manager;

- (id) initWithURL: (NSURL *) url {
	if (self = [super init]) {
		_baseURL = url;
		
		manager = [self createHTTPSessionManager:_baseURL];
	}
	
	return self;
}

- (void) loginWithParameters: (NSDictionary *) parameters {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [_baseURL absoluteString], @"api/login"];
	[manager POST:url parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
		User *user = [[User alloc] initWithJSON:responseObject];
		
		if (delegate) {
			[delegate authenticationWasSuccessful:user];
		}
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		if (delegate) {
			[delegate authenticationHadFailure];
		}
	}];
}

- (AFHTTPSessionManager *) createHTTPSessionManager: (NSURL *) url {
	AFHTTPSessionManager *m = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
	m.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
	m.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONReadingAllowFragments];
	
	return m;
}

@end