//
//  LocalAuthentication.m
//  mage-ios-sdk
//
//

#import "LocalAuthentication.h"

#import <AFNetworking/AFNetworking.h>

#import "User.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "StoredPassword.h"
#import "UserUtility.h"

@interface LocalAuthentication()

@property (strong, nonatomic) NSDictionary* parameters;
@property (strong, nonatomic) NSDictionary *loginParameters;

@end

@implementation LocalAuthentication

- (instancetype) initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self == nil) return nil;
    
    self.parameters = parameters;
    
    return self;
}

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return [url isEqualToString:[self.loginParameters objectForKey:@"serverUrl"]];
}

- (void) loginWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = (NSString *) [loginParameters objectForKey:@"username"];
    NSString *password = (NSString *) [loginParameters objectForKey:@"password"];
    
    NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
    if (oldLoginParameters != nil) {
        NSString *oldUsername = [oldLoginParameters objectForKey:@"username"];
        NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
        NSString *oldPassword = [StoredPassword retrieveStoredPassword];
        if (oldUsername != nil && oldPassword != nil && [oldUsername isEqualToString:username] && [oldPassword isEqualToString:password] && [oldUrl isEqualToString:[[MageServer baseURL] absoluteString]]) {
            self.loginParameters = loginParameters;
            complete(AUTHENTICATION_SUCCESS, nil);
            return;
        }
    }
    
    complete(AUTHENTICATION_ERROR, @"Error logging in");
}

- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
    
    NSTimeInterval tokenExpirationLength = [[defaults objectForKey:@"tokenExpirationLength"] doubleValue];
    NSDate *newExpirationDate = [[NSDate date] dateByAddingTimeInterval:tokenExpirationLength];
    NSMutableDictionary *newLoginParameters = [NSMutableDictionary dictionaryWithDictionary:oldLoginParameters];
    [newLoginParameters setValue:newExpirationDate forKey:@"tokenExpirationDate"];
    [defaults setObject:newLoginParameters forKey:@"loginParameters"];
    [defaults setValue:[Authentication authenticationTypeToString:LOCAL] forKey:@"loginType"];
    [defaults synchronize];
    [[UserUtility singleton] resetExpiration];
    
    [MageSessionManager manager].token = [oldLoginParameters objectForKey:@"token"];
    complete(AUTHENTICATION_SUCCESS, nil);
}

@end
