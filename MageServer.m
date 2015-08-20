//
//  MageServer.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MageServer.h"
#import "HttpManager.h"

NSString * const kServerMajorVersionKey = @"serverMajorVersion";
NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

+ (NSURL *) baseURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:kBaseServerUrlKey];
    return [NSURL URLWithString:url];
}

static MageServer *sharedSingleton = nil;

+ (MageServer *) singleton {
    
    if (sharedSingleton == nil) {
        sharedSingleton = [[super allocWithZone:NULL] init];
    }
    
    return sharedSingleton;
}

- (id) setupServerWithURL:(NSURL *) url success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[url absoluteString] forKey:kBaseServerUrlKey];
    [defaults synchronize];
    
    self.reachabilityManager = [AFNetworkReachabilityManager managerForDomain:url.host];
    
// TODO see if I can get this to work for IP address
//    struct sockaddr_in address;
//    address.sin_len = sizeof(address);
//    address.sin_family = AF_INET;
//    address.sin_port = htons(url.port);
//    address.sin_addr.s_addr = inet_addr([url.host UTF8String]);
//    self.reachabilityManager = [AFNetworkReachabilityManager managerForAddress:&address];
    
    [self.reachabilityManager startMonitoring];
    
    HttpManager *http = [HttpManager singleton];
    NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
    [http.manager GET:apiURL parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        // TODO at some point we could read the server response and create the correct authentication module.
        // For now just create the local (username/password) authentication module.
        self.authentication = [Authentication authenticationWithType:SERVER];
        
        // TODO check server version
        NSNumber *serverCompatibilityVersion = [defaults valueForKey:kServerMajorVersionKey];
        NSNumber *serverVersion = [response valueForKeyPath:@"version.major"];
        NSLog(@"Server compat version %@", serverCompatibilityVersion);
        NSLog(@"Server version %@", [response valueForKeyPath:@"version.major"]);
        if (serverCompatibilityVersion == serverVersion) {
            success();
        } else {
            failure([[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"This version of the app is not compatible with version %@.%@.%@ of the server.", [response valueForKeyPath:@"version.major"], [response valueForKeyPath:@"version.minor"], [response valueForKeyPath:@"version.micro"]]  forKey:NSLocalizedDescriptionKey]]);
        }
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        // check if the error indicates that the network is unavailable
        // and return a local authentication module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
            || error.code == NSURLErrorNetworkConnectionLost
            || error.code == NSURLErrorNotConnectedToInternet)) {
            self.authentication = [Authentication authenticationWithType:LOCAL];
                if ([self.authentication canHandleLoginToURL:[url absoluteString]]) {
                    success();
                } else {
                    failure(error);
                }
        } else {
            failure(error);
        }
    }];
    
    return self;
}

@end
