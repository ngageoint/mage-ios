//
//  MageServer.m
//  mage-ios-sdk
//
//

#import "MageServer.h"
#import "HttpManager.h"

NSString * const kServerMajorVersionKey = @"serverMajorVersion";
NSString * const kServerMinorVersionKey = @"serverMinorVersion";

NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

+ (NSURL *) baseURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:kBaseServerUrlKey];
    return [NSURL URLWithString:url];
}

+ (void) serverWithURL:(NSURL *) url authenticationDelegate:(id<AuthenticationDelegate>) authenticationDelegate success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure {
    
    if (!url || !url.scheme || !url.host) {
        failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Invalid URL" forKey:NSLocalizedDescriptionKey]]);
        return;
    }
    
    MageServer *server = [[MageServer alloc] init];
    
    server.reachabilityManager = [AFNetworkReachabilityManager managerForDomain:url.host];
    [server.reachabilityManager startMonitoring];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([url.absoluteString isEqualToString:[defaults valueForKey:kBaseServerUrlKey]] && server.authentication) {
        success(server);
        return;
    }
    
    HttpManager *http = [HttpManager singleton];
    NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
    [http.manager GET:apiURL parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        // TODO at some point we could read the server response and create the correct authentication module.
        // For now just create the local (username/password) authentication module.
        server.authentication = [Authentication authenticationWithType:SERVER];
        server.authentication.delegate = authenticationDelegate;
        
        // TODO check server version
        NSNumber *serverCompatibilityMajorVersion = [defaults valueForKey:kServerMajorVersionKey];
        NSNumber *serverCompatibilityMinorVersion = [defaults valueForKey:kServerMinorVersionKey];

        NSNumber *serverMajorVersion = [response valueForKeyPath:@"version.major"];
        NSNumber *serverMinorVersion = [response valueForKeyPath:@"version.minor"];
        
        [defaults setObject:[response valueForKeyPath:@"disclaimer.show"] forKey:@"showDisclaimer"];
        [defaults setObject:[response valueForKeyPath:@"disclaimer.text"] forKey:@"disclaimerText"];
        [defaults setObject:[response valueForKeyPath:@"disclaimer.title"] forKey:@"disclaimerTitle"];
        
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
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        // check if the error indicates that the network is unavailable
        // and return a local authentication module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
            || error.code == NSURLErrorNetworkConnectionLost
            || error.code == NSURLErrorNotConnectedToInternet)) {
            server.authentication = [Authentication authenticationWithType:LOCAL];
                if ([server.authentication canHandleLoginToURL:[url absoluteString]]) {
                    success(server);
                } else {
                    failure(error);
                }
        } else {
            failure(error);
        }
    }];
}

@end
