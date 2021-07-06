//
//  MageServer.m
//  mage-ios-sdk
//
//

#import "MageServer.h"
#import "MageSessionManager.h"
#import "LdapAuthentication.h"
#import "LocalAuthentication.h"
#import "ServerAuthentication.h"
#import "IdpAuthentication.h"
#import "StoredPassword.h"

NSString * const kServerCompatibilitiesKey = @"serverCompatibilities";
NSString * const kServerMajorVersionKey = @"serverMajorVersion";
NSString * const kServerMinorVersionKey = @"serverMinorVersion";
NSString * const kServerAuthenticationStrategiesKey = @"serverAuthenticationStrategies";

NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

- (instancetype) initWithURL: (NSURL *) url {
    if (self = [super init]) {
        
        if (![url.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kBaseServerUrlKey]]) {
            return self;
        }
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *authenticationStrategies = [defaults valueForKeyPath:@"authenticationStrategies"];
        
        if (authenticationStrategies) {
            NSMutableDictionary *authenticationModules = [[NSMutableDictionary alloc] init];
            [defaults setObject:authenticationStrategies forKey:kServerAuthenticationStrategiesKey];
            for (NSString *authenticationStrategy in authenticationStrategies) {
                NSDictionary *parameters = [authenticationStrategies objectForKey:authenticationStrategy];
                id authenticationModule = [Authentication authenticationModuleForStrategy:authenticationStrategy parameters:parameters];
                if (authenticationModule) {
                    [authenticationModules setObject:authenticationModule forKey:authenticationStrategy];
                }
            }
            
            NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
            if (oldLoginParameters != nil) {
                NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
                if ([oldUrl isEqualToString:[url absoluteString]] && [StoredPassword retrieveStoredPassword] != nil) {
                    [authenticationModules setObject:[Authentication authenticationModuleForStrategy:@"offline" parameters:nil] forKey:@"offline"];
                }
            }
            
            self.authenticationModules = authenticationModules;
        }
    }
    
    return self;
}

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

- (NSArray *) getStrategies {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultStrategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
    NSMutableArray *strategies = [[NSMutableArray alloc] init];
    [defaultStrategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"local"]) {
            [strategies addObject:@{@"identifier": key, @"strategy": obj}];
        } else {
            [strategies insertObject:@{@"identifier": key, @"strategy": obj} atIndex:0];
        }
    }];
    return strategies;
}

- (NSArray *) getOauthStrategies {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
    NSMutableArray *oauthStrategies = [[NSMutableArray alloc] init];
    [strategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([[obj objectForKey:@"type"] isEqualToString:@"oauth2"]) {
            [oauthStrategies addObject:@{@"identifier": key, @"strategy": obj}];
        }
    }];
    return oauthStrategies;
}

+ (BOOL) checkServerCompatibility: (NSDictionary *) api {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *serverCompatibilities  = [defaults arrayForKey:kServerCompatibilitiesKey];
    
    for (NSDictionary *compatibility in serverCompatibilities) {
        NSNumber *serverCompatibilityMajorVersion = [compatibility valueForKey:kServerMajorVersionKey];
        NSNumber *serverCompatibilityMinorVersion = [compatibility valueForKey:kServerMinorVersionKey];
        
        NSNumber *serverMajorVersion = [api valueForKeyPath:@"version.major"];
        NSNumber *serverMinorVersion = [api valueForKeyPath:@"version.minor"];
        
        if ([serverCompatibilityMajorVersion intValue] == [serverMajorVersion intValue] && [serverCompatibilityMinorVersion intValue] <= [serverMinorVersion intValue]) {
            // server is compatible.  save the version
            [defaults setObject:[api valueForKeyPath:@"version.major"] forKey:@"serverMajorVersion"];
            [defaults setObject:[api valueForKeyPath:@"version.minor"] forKey:@"serverMinorVersion"];
            [defaults synchronize];
            return true;
        }
    }
    return false;
}

+ (NSError *) generateServerCompatibilityError: (NSDictionary *) api {
    if (!api || ![api valueForKey:@"version"]) {
        return [[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid server response %@", api] forKey:NSLocalizedDescriptionKey]];
    }
    return [[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"This version of the app is not compatible with version %@.%@.%@ of the server.  Please contact your MAGE administrator for more information.", [api valueForKeyPath:@"version.major"], [api valueForKeyPath:@"version.minor"], [api valueForKeyPath:@"version.micro"]]  forKey:NSLocalizedDescriptionKey]];
}

+ (BOOL) isServerVersion5 {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"serverMajorVersion"] == 5;
}

+ (void) serverWithURL:(NSURL *) url success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure {
    
    if (!url || !url.scheme || !url.host) {
        failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Invalid URL" forKey:NSLocalizedDescriptionKey]]);
        return;
    }
    
    MageServer *server = [[MageServer alloc] initWithURL: url];
    if ([url.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kBaseServerUrlKey]] && server.authenticationModules) {
        success(server);
        return;
    }
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
    NSURLSessionDataTask *task = [manager GET_TASK:apiURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id response) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([response isKindOfClass:[NSData class]]) {
            if (((NSData *)response).length == 0) {
                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Empty API response received from server." forKey:NSLocalizedDescriptionKey]]);
                return;
            }
            // try to turn it into a string in case it was HTML
            NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            if (responseString) {
                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Invalid API response received from server. %@", responseString] forKey:NSLocalizedDescriptionKey]]);
                return;
            }
        }
        
        if (![response isKindOfClass:[NSDictionary class]]) {
            failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Unknown API response received from server. %@", task.response.MIMEType] forKey:NSLocalizedDescriptionKey]]);
            return;
        }
        
        if ([MageServer checkServerCompatibility:response]) {
            [defaults setObject:[url absoluteString] forKey:kBaseServerUrlKey];
            [defaults synchronize];
        } else {
            failure([MageServer generateServerCompatibilityError:response]);
            return;
        }
        
        NSDictionary *disclaimer = [response valueForKey:@"disclaimer"];
        if (disclaimer) {
            [defaults setObject:[disclaimer valueForKeyPath:@"show"] forKey:@"showDisclaimer"];
            [defaults setObject:[disclaimer valueForKeyPath:@"text"] forKey:@"disclaimerText"];
            [defaults setObject:[disclaimer valueForKeyPath:@"title"] forKey:@"disclaimerTitle"];
        }
        
        if (![response valueForKeyPath:@"authenticationStrategies"]) {
            failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Invalid response from the MAGE server. %@", response] forKey:NSLocalizedDescriptionKey]]);
            return;
        }
        [defaults setObject:[response valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
        
        NSMutableDictionary *authenticationModules = [[NSMutableDictionary alloc] init];
        NSDictionary *authenticationStrategies = [response valueForKeyPath:@"authenticationStrategies"];
        [defaults setObject:authenticationStrategies forKey:kServerAuthenticationStrategiesKey];
        for (NSString *authenticationStrategy in authenticationStrategies) {
            NSDictionary *parameters = [authenticationStrategies objectForKey:authenticationStrategy];
            id authenticationModule = [Authentication authenticationModuleForStrategy:authenticationStrategy parameters:parameters];
            if (authenticationModule) {
                [authenticationModules setObject:authenticationModule forKey:authenticationStrategy];
            }
        }
        NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
        if (oldLoginParameters != nil) {
            NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
            if ([oldUrl isEqualToString:[url absoluteString]] && [StoredPassword retrieveStoredPassword] != nil) {
                [authenticationModules setObject:[Authentication authenticationModuleForStrategy:@"offline" parameters:nil] forKey:@"offline"];
            }
        }
        
        server.authenticationModules = authenticationModules;
        
        [defaults synchronize];
        
        success(server);
        return;
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        // check if the error indicates that the network is unavailable and return the offline authentication module
        if ([error.domain isEqualToString:NSURLErrorDomain]
            && (error.code == NSURLErrorCannotConnectToHost
                || error.code == NSURLErrorNetworkConnectionLost
                || error.code == NSURLErrorNotConnectedToInternet
                || error.code == NSURLErrorTimedOut
                )) {
                id<Authentication> authentication = [Authentication authenticationModuleForStrategy:@"offline" parameters:nil];
                if ([authentication canHandleLoginToURL:[url absoluteString]]) {
                    server.authenticationModules = [NSDictionary dictionaryWithObject:authentication forKey:@"offline"];
                }
                success(server);
            } else {
                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Failed to connect to server.  Received error %@", error.localizedDescription] forKey:NSLocalizedDescriptionKey]]);
            }
    }];
    
    [manager addTask:task];
    
}

@end
