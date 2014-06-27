//
//  Authentication.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Authentication.h"
#import "LocalAuthentication.h"

@implementation Authentication

+ (id) authenticationWithType: (AuthenticationType) type url: (NSURL *) url inManagedObjectContext: (NSManagedObjectContext *) context {
	switch(type) {
		case LOCAL: {
			return [[LocalAuthentication alloc] initWithURL:url inManagedObjectContext:context];
		}
		default: {
			return nil;
		}
	}
	
}

@end