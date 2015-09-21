//
//  LocalAuthentication.m
//  mage-ios-sdk
//
//

#import "LocalAuthentication.h"

#import <AFNetworking/AFNetworking.h>

#import "User+helper.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "StoredPassword.h"
#import "UserUtility.h"

@implementation LocalAuthentication

@synthesize delegate;

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (void) loginWithParameters: (NSDictionary *) parameters  {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *username = (NSString *) [parameters objectForKey:@"username"];
    NSString *password = (NSString *) [parameters objectForKey:@"password"];
    
    NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
    if (oldLoginParameters != nil) {
        NSString *oldUsername = [oldLoginParameters objectForKey:@"username"];
        NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
        NSString *oldPassword = [StoredPassword retrieveStoredPassword];
        if (oldUsername != nil && oldPassword != nil && [oldUsername isEqualToString:username] && [oldPassword isEqualToString:password] && [oldUrl isEqualToString:[[MageServer baseURL] absoluteString]]) {
            HttpManager *http = [HttpManager singleton];
            NSTimeInterval tokenExpirationLength = [[defaults objectForKey:@"tokenExpirationLength"] doubleValue];
            NSDate *newExpirationDate = [[NSDate date] dateByAddingTimeInterval:tokenExpirationLength];
            NSMutableDictionary *newLoginParameters = [NSMutableDictionary dictionaryWithDictionary:oldLoginParameters];
            [newLoginParameters setValue:newExpirationDate forKey:@"tokenExpirationDate"];
            [defaults setObject:newLoginParameters forKey:@"loginParameters"];
            [defaults synchronize];
            [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [oldLoginParameters objectForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
            [http.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [oldLoginParameters objectForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
            [[UserUtility singleton] resetExpiration];
            if (delegate) {
                User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
                [delegate authenticationWasSuccessful];
            }
            return;
        }
    }
    if (delegate) {
        [delegate authenticationHadFailure];
    }
    return;
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return [url isEqualToString:[self.loginParameters objectForKey:@"serverUrl"]];
}

@end