//
//  ServerAuthentication.m
//  mage-ios-sdk
//
//

#import "ServerAuthentication.h"
#import "StoredPassword.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "User.h"
#import "UserUtility.h"
#import "NSDate+Iso8601.h"

@interface ServerAuthentication()

@property (strong, nonatomic) NSDictionary *parameters;
@property (strong, nonatomic) NSDictionary *loginParameters;
@property (strong, nonatomic) NSDictionary *response;
@end

@implementation ServerAuthentication

- (instancetype) initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self == nil) return nil;
    
    self.parameters = parameters;
    
    return self;
}

- (void) loginWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/login"];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:loginParameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSDictionary *api = [response objectForKey:@"api"];
        BOOL serverCompatible = [MageServer checkServerCompatibility:api];
        if (!serverCompatible) {
            NSError *error = [MageServer generateServerCompatibilityError:api];
            return complete(AUTHENTICATION_ERROR, error.localizedDescription);
        }
        self.loginParameters = loginParameters;
        self.response = response;
        [self finishLoginForParameters: loginParameters withResponse:response complete:complete];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        // if the error was a network error try to login with the local auth module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNotConnectedToInternet
                )) {
                NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
                // at this point, we might not have a connection to the server.
                complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
            } else {
                NSLog(@"Error logging in: %@", error);
                // try to register again
                [defaults setBool:NO forKey:@"deviceRegistered"];
                [self registerDevice:loginParameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
                    if (authenticationStatus == AUTHENTICATION_ERROR) {
                        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                        complete(authenticationStatus, errResponse);
                    } else {
                        complete(authenticationStatus, errorString);
                    }
                }];
            }
    }];
    
    [manager addTask:task];
}

- (BOOL) canHandleLoginToURL: (NSString *) url {
    return YES;
}

- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *api = [self.response objectForKey:@"api"];
    
    if ([api valueForKey:@"disclaimer"]) {
        [defaults setObject:[api valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
    }
    [defaults setObject:[api valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
    
    NSDictionary *userJson = [self.response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
        if (!user) {
            [User insertUserForJson:userJson inManagedObjectContext:localContext];
        } else {
            [user updateUserForJson:userJson];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSString *token = [self.response objectForKey:@"token"];
        NSString *username = (NSString *) [self.loginParameters objectForKey:@"username"];
        NSString *password = (NSString *) [self.loginParameters objectForKey:@"password"];
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[self.response objectForKey:@"expirationDate"]];
        
        [MageSessionManager manager].token = token;
        
        [[UserUtility singleton] resetExpiration];
        
        NSDictionary *loginParameters = @{
                                          @"username": username,
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        
        NSDictionary *userJson = [self.response objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        [defaults setObject: userId forKey:@"currentUserId"];
        
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults setBool:YES forKey:@"deviceRegistered"];
        [defaults setValue:[Authentication authenticationTypeToString:SERVER] forKey:@"loginType"];
        [defaults synchronize];
        [StoredPassword persistPasswordToKeyChain:password];
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) finishLoginForParameters: (NSDictionary *) parameters withResponse: (NSDictionary *) response complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *api = [response objectForKey:@"api"];

    if ([api valueForKey:@"disclaimer"]) {
        [defaults setObject:[api valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[api valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
    }
    [defaults setObject:[api valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
    
    NSDictionary *userJson = [response objectForKey:@"user"];
    NSString *userId = [userJson objectForKey:@"id"];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *user = [User fetchUserForId:userId inManagedObjectContext:localContext];
        if (!user) {
            [User insertUserForJson:userJson inManagedObjectContext:localContext];
        } else {
            [user updateUserForJson:userJson];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        NSString *token = [response objectForKey:@"token"];
        NSString *username = (NSString *) [parameters objectForKey:@"username"];
        NSString *password = (NSString *) [parameters objectForKey:@"password"];
        // Always use this locale when parsing fixed format date strings
        NSDate* tokenExpirationDate = [NSDate dateFromIso8601String:[response objectForKey:@"expirationDate"]];
        
        [MageSessionManager manager].token = token;
        
        [[UserUtility singleton] resetExpiration];
        
        NSDictionary *loginParameters = @{
                                          @"username": username,
                                          @"serverUrl": [[MageServer baseURL] absoluteString],
                                          @"tokenExpirationDate": tokenExpirationDate
                                          };
        
        [defaults setObject:loginParameters forKey:@"loginParameters"];
        
        NSDictionary *userJson = [response objectForKey:@"user"];
        NSString *userId = [userJson objectForKey:@"id"];
        [defaults setObject: userId forKey:@"currentUserId"];
        
        NSTimeInterval tokenExpirationLength = [tokenExpirationDate timeIntervalSinceNow];
        [defaults setObject:[NSNumber numberWithDouble:tokenExpirationLength] forKey:@"tokenExpirationLength"];
        [defaults setBool:YES forKey:@"deviceRegistered"];
        [defaults setValue:[Authentication authenticationTypeToString:SERVER] forKey:@"loginType"];
        [defaults synchronize];
        [StoredPassword persistPasswordToKeyChain:password];
        [StoredPassword persistTokenToKeyChain:token];
        
        complete(AUTHENTICATION_SUCCESS, nil);
    }];
}

- (void) registerDevice: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete {
    NSLog(@"Registering device");
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"api/devices"];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        BOOL registered = [[response objectForKey:@"registered"] boolValue];
        if (registered) {
            NSLog(@"Device was registered already, logging in");
            [defaults setBool:YES forKey:@"deviceRegistered"];
            // device was already registered, log in
            [self loginWithParameters:parameters complete:complete];
        } else {
            NSLog(@"Registration was successful");
            complete(REGISTRATION_SUCCESS, nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNotConnectedToInternet
                ))
        {
            NSLog(@"Unable to authenticate, probably due to no connection.  Error: %@", error);
            // at this point, we might not have a connection to the server.
            complete(UNABLE_TO_AUTHENTICATE, error.localizedDescription);
        } else {
            complete(AUTHENTICATION_ERROR, errResponse);
        }
    }];
    
    [manager addTask:task];
}

@end
