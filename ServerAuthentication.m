//
//  ServerAuthentication.m
//  mage-ios-sdk
//
//

#import "ServerAuthentication.h"
#import "StoredPassword.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "User+helper.h"
#import "UserUtility.h"
#import "NSDate+iso8601.h"

@implementation ServerAuthentication

- (NSDictionary *) loginParameters {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"loginParameters"];
}

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    BOOL registered = [defaults boolForKey:@"deviceRegistered"];
    NSLog(@"registered? %d", registered);
    
    // if we think we need to register, go do it
    if (![defaults boolForKey:@"deviceRegistered"]) {
        NSLog(@"Not registered");
        [self registerDevice:parameters complete:complete];
    } else {
        NSLog(@"Registered in theory, just log in");
        [self performLogin:parameters complete:complete];
    }
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) performLogin: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/login"];
    
    [http.manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        NSDictionary *userJson = [response objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
            if (!user) {
                user = [User insertUserForJson:userJson inManagedObjectContext:localContext];
            } else {
                [user updateUserForJson:userJson];
            }
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            [self finishLoginForParameters: parameters withResponse:response complete:complete];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // if the error was a network error try to login with the local auth module
        if ([error.domain isEqualToString:NSURLErrorDomain]
        && (error.code == NSURLErrorCannotConnectToHost
            || error.code == NSURLErrorNetworkConnectionLost
            || error.code == NSURLErrorNotConnectedToInternet)) {
            id<Authentication> local = [Authentication authenticationModuleForType:LOCAL];
            [local loginWithParameters:parameters complete:complete];
        } else {
            NSLog(@"Error logging in: %@", error);
            // try to register again
            [defaults setBool:NO forKey:@"deviceRegistered"];
            [self registerDevice:parameters complete:complete];
        }
        
    }];

}

- (void) finishLoginForParameters: (NSDictionary *) parameters withResponse: (NSDictionary *) response complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {

    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *token = [response objectForKey:@"token"];
    NSString *username = (NSString *) [parameters objectForKey:@"username"];
    NSString *password = (NSString *) [parameters objectForKey:@"password"];
    // Always use this locale when parsing fixed format date strings
    NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[response objectForKey:@"expirationDate"]];
    HttpManager *http = [HttpManager singleton];

    [http.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [http.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [[UserUtility singleton] resetExpiration];

    NSDictionary *loginParameters = @{
                                   @"username": username,
                                   @"serverUrl": [[MageServer baseURL] absoluteString],
                                   @"token": token,
                                   @"tokenExpirationDate": tokenExpirationDate
                                   };

    [defaults setObject:loginParameters forKey:@"loginParameters"];
    
    NSDictionary *userJson = [response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    [defaults setObject: userId forKey:@"currentUserId"];
    
    NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
    [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
    [defaults synchronize];
    [StoredPassword persistPasswordToKeyChain:password];
    
    complete(AUTHENTICATION_SUCCESS);
}

- (void) registerDevice: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) complete {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    HttpManager *http = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/devices"];
    [http.manager POST: url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        BOOL registered = [[response objectForKey:@"registered"] boolValue];
        if (registered) {
            NSLog(@"Device was registered already, logging in");
            [defaults setBool:YES forKey:@"deviceRegistered"];
            // device was already registered, log in
            [self performLogin:parameters complete:complete];
        } else {
            NSLog(@"Registration was successful");
            complete(REGISTRATION_SUCCESS);
        }
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        complete(AUTHENTICATION_ERROR);
    }];
}

@end
