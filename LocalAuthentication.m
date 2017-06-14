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

@implementation LocalAuthentication

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return [url isEqualToString:[self.loginParameters objectForKey:@"serverUrl"]];
}

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *username = (NSString *) [parameters objectForKey:@"username"];
    NSString *password = (NSString *) [parameters objectForKey:@"password"];
    
    NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
    if (oldLoginParameters != nil) {
        NSString *oldUsername = [oldLoginParameters objectForKey:@"username"];
        NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
        NSString *oldPassword = [StoredPassword retrieveStoredPassword];
        if (oldUsername != nil && oldPassword != nil && [oldUsername isEqualToString:username] && [oldPassword isEqualToString:password] && [oldUrl isEqualToString:[[MageServer baseURL] absoluteString]]) {
            NSTimeInterval tokenExpirationLength = [[defaults objectForKey:@"tokenExpirationLength"] doubleValue];
            NSDate *newExpirationDate = [[NSDate date] dateByAddingTimeInterval:tokenExpirationLength];
            NSMutableDictionary *newLoginParameters = [NSMutableDictionary dictionaryWithDictionary:oldLoginParameters];
            [newLoginParameters setValue:newExpirationDate forKey:@"tokenExpirationDate"];
            [defaults setObject:newLoginParameters forKey:@"loginParameters"];
            [defaults synchronize];
            [[UserUtility singleton] resetExpiration];
            
            [MageSessionManager manager].token = [oldLoginParameters objectForKey:@"token"];
            
            complete(AUTHENTICATION_SUCCESS);
            return;
        }
    }
    
    complete(AUTHENTICATION_ERROR);
}

@end
