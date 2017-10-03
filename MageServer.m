//
//  MageServer.m
//  mage-ios-sdk
//
//

#import "MageServer.h"
#import "MageSessionManager.h"
#import "LocalAuthentication.h"
#import "ServerAuthentication.h"
#import "OAuthAuthentication.h"

NSString * const kServerMajorVersionKey = @"serverMajorVersion";
NSString * const kServerMinorVersionKey = @"serverMinorVersion";
NSString * const kServerAuthenticationStrategiesKey = @"serverAuthenticationStrategies";

NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

+ (NSURL *) baseURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:kBaseServerUrlKey];
    return [NSURL URLWithString:url];
}

- (BOOL) serverHasLocalAuthenticationStrategy {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
    return [strategies objectForKey:@"local"] != nil;
}

- (BOOL) serverHasGoogleAuthenticationStrategy {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
    return [strategies objectForKey:@"google"] != nil;
}

+ (void) serverWithURL:(NSURL *) url success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure {
    
    if (!url || !url.scheme || !url.host) {
        failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Invalid URL" forKey:NSLocalizedDescriptionKey]]);
        return;
    }
    
    MageServer *server = [[MageServer alloc] init];
    
    server.reachabilityManager = [AFNetworkReachabilityManager managerForDomain:url.host];
    [server.reachabilityManager startMonitoring];
    
    if ([url.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kBaseServerUrlKey]] && server.authenticationModules) {
        success(server);
        return;
    }
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
    NSURLSessionDataTask *task = [manager GET_TASK:apiURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id response) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSNumber *serverCompatibilityMajorVersion = [defaults valueForKey:kServerMajorVersionKey];
        NSNumber *serverCompatibilityMinorVersion = [defaults valueForKey:kServerMinorVersionKey];
        
        NSNumber *serverMajorVersion = [response valueForKeyPath:@"version.major"];
        NSNumber *serverMinorVersion = [response valueForKeyPath:@"version.minor"];
        
        [defaults setObject:[response valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[response valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[response valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
        
        NSMutableDictionary *authenticationModules = [NSMutableDictionary dictionaryWithObject:[[LocalAuthentication alloc] init] forKey:[Authentication authenticationTypeToString:LOCAL]];
        NSDictionary *authenticationStrategies = [response valueForKeyPath:@"authenticationStrategies"];
        [defaults setObject:authenticationStrategies forKey:kServerAuthenticationStrategiesKey];
        for (NSString *authenticationType in authenticationStrategies) {
            NSDictionary *authParams = [authenticationStrategies objectForKey:authenticationType];
            if ([authenticationType isEqualToString:@"google"]) {
                [authenticationModules setObject:[[OAuthAuthentication alloc] initWithParameters: authParams] forKey:[Authentication authenticationTypeToString:GOOGLE]];
            } else if ([authenticationType isEqualToString:@"local"]) {
                [authenticationModules setObject:[[ServerAuthentication alloc] initWithParameters: authParams] forKey:[Authentication authenticationTypeToString:SERVER]];
            }
        }
        server.authenticationModules = authenticationModules;
        
        [defaults synchronize];
        
        if (serverCompatibilityMajorVersion == serverMajorVersion && serverCompatibilityMinorVersion <= serverMinorVersion) {
            [defaults setObject:[url absoluteString] forKey:kBaseServerUrlKey];
            [defaults synchronize];
            success(server);
            return;
        } else {
            failure([[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"This version of the app is not compatible with version %@.%@.%@ of the server.", [response valueForKeyPath:@"version.major"], [response valueForKeyPath:@"version.minor"], [response valueForKeyPath:@"version.micro"]]  forKey:NSLocalizedDescriptionKey]]);
            return;
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        // check if the error indicates that the network is unavailable
        // and return a local authentication module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNetworkConnectionLost
                || error.code == NSURLErrorNotConnectedToInternet
                || error.code == NSURLErrorTimedOut)) {
                id<Authentication> authentication = [Authentication authenticationModuleForType:LOCAL];
                if ([authentication canHandleLoginToURL:[url absoluteString]]) {
                    server.authenticationModules = [NSDictionary dictionaryWithObject:authentication forKey:[Authentication authenticationTypeToString:LOCAL]];
                    success(server);
                } else {
                    failure(error);
                }
            } else {
                failure(error);
            }
    }];
    
    [manager addTask:task];
    
}

@end
