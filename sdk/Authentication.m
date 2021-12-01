//
//  Authentication.m
//  mage-ios-sdk
//

#import "Authentication.h"
#import "LocalAuthentication.h"
#import "ServerAuthentication.h"
#import "IdpAuthentication.h"
#import "LdapAuthentication.h"

@interface Authentication ()

@end

@implementation Authentication

+ (id<AuthenticationProtocol>) authenticationModuleForStrategy: (NSString *) strategy parameters:(NSDictionary *) parameters {
    if ([Authentication isLocalStrategy:strategy]) {
        return [[ServerAuthentication alloc] initWithParameters:parameters];
    } else if ([Authentication isLdapStrategy:strategy]) {
        return [[LdapAuthentication alloc] initWithParameters:parameters];
    } else if ([Authentication isOfflineStrategy:strategy]) {
        return [[LocalAuthentication alloc] initWithParameters:parameters];
    } else if ([Authentication isIdpStrategy:strategy]) {
        return [[IdpAuthentication alloc] initWithParameters:parameters];
    } else {
        return nil;
    }
}

+ (Boolean) isLocalStrategy:(NSString *) strategy {
    return [@"local" isEqualToString:strategy];
}

+ (Boolean) isLdapStrategy:(NSString *) strategy {
    return [@"ldap" isEqualToString:strategy];
}

+ (Boolean) isOfflineStrategy:(NSString *) strategy {
    return [@"offline" isEqualToString:strategy];
}

+ (Boolean) isIdpStrategy:(NSString *) strategy {
    return [@"saml" isEqualToString:strategy] ||
        [@"google" isEqualToString:strategy] ||
        [@"oauth" isEqualToString:strategy] ||
        [@"geoaxis" isEqualToString:strategy];
}

@end
