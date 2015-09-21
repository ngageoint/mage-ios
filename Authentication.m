//
//  Authentication.m
//  mage-ios-sdk
//
//

#import "Authentication.h"
#import "LocalAuthentication.h"
#import "ServerAuthentication.h"

@implementation Authentication

+ (id) authenticationWithType: (AuthenticationType) type {
	switch(type) {
		case LOCAL: {
			return [[LocalAuthentication alloc] init];
		}
        case SERVER: {
            return [[ServerAuthentication alloc] init];
        }
		default: {
			return nil;
		}
	}
	
}

@end