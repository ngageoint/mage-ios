//
//  Authentication.m
//  mage-ios-sdk
//
//

#import "Authentication.h"
#import "LocalAuthentication.h"
#import "ServerAuthentication.h"
#import "GoogleAuthentication.h"

@interface Authentication ()

@end

@implementation Authentication

+ (id) authenticationModuleForType: (AuthenticationType) type {
	switch(type) {
		case LOCAL: {
			return [[LocalAuthentication alloc] init];
		}
        case SERVER: {
            return [[ServerAuthentication alloc] init];
        }
        case GOOGLE: {
            return [[GoogleAuthentication alloc] init];
        }
		default: {
			return nil;
		}
	}
	
}

+ (AuthenticationType) authenticationTypeFromString: (NSString *) value {
    return [[Authentication stringToAuthenticationType] objectForKey:value];
}

+ (NSString *) authenticationTypeToString: (AuthenticationType) authenticationType {
    return [[Authentication authenticationTypeToString] objectForKey:[NSNumber numberWithInteger:authenticationType]];
}

+ (NSDictionary *) stringToAuthenticationType {
    static NSDictionary *dictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInteger:LOCAL], @"local",
                      [NSNumber numberWithInteger:SERVER], @"server",
                      [NSNumber numberWithInteger:GOOGLE], @"google",
                      nil];
    });
    
    return dictionary;
}

+ (NSDictionary *) authenticationTypeToString {
    static NSDictionary *dictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"local", [NSNumber numberWithInteger:LOCAL],
                      @"server", [NSNumber numberWithInteger:SERVER],
                      @"google", [NSNumber numberWithInteger:GOOGLE],
                      nil];
    });
    
    return dictionary;
}

@end