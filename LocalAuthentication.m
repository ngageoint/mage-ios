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

- (id) initWithURL: (NSURL *) url {
	if (self = [super init]) {
		_baseURL = url;
	}
	
	return self;
}

- (void) loginWithParameters: (NSDictionary *) parameters {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
	manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONReadingAllowFragments];
	
	NSString *url = [NSString stringWithFormat:@"%@/%@", [_baseURL absoluteString], @"api/login"];
	[manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		User *user = [[User alloc] initWithJSON:responseObject];
		
		if (delegate) {
			[delegate authenticationWasSuccessful:user];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (delegate) {
			[delegate authenticationHadFailure];
		}
	}];
}

@end