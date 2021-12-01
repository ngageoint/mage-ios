//
//  MageServer.m
//  mage-ios-sdk
//
//

import Foundation

@objc class MageServer: NSObject {
    
    static let kServerCompatibilitiesKey = "serverCompatibilities"
    static let kServerMajorVersionKey = "serverMajorVersion"
    static let kServerMinorVersionKey = "serverMinorVersion"
    static let kServerAuthenticationStrategiesKey = "serverAuthenticationStrategies"
    
    @objc public var authenticationModules: [AnyHashable: Any]?
    
    @objc public static func baseURL() -> URL? {
        if let baseServerUrl = UserDefaults.standard.baseServerUrl {
            return URL(string: baseServerUrl)
        }
        return nil
    }
    
    @objc public var serverHasLocalAuthenticationStrategy: Bool {
        get {
            if let strategies = UserDefaults.standard.serverAuthenticationStrategies, strategies["local"] != nil {
                return true
            }
            return false
        }
    }
    
    @objc public static var isServerVersion5: Bool {
        get {
            return UserDefaults.standard.serverMajorVersion == 5
        }
    }
    
    @objc public static var isServerVersion6_0: Bool {
        get {
            return UserDefaults.standard.serverMajorVersion == 6 && UserDefaults.standard.serverMinorVersion == 0
        }
    }
    
    @objc public var oauthStrategies: [[String: Any]] {
        get {
            var _oauthStrategies:[[String: Any]] = []
            if let strategies = UserDefaults.standard.serverAuthenticationStrategies as? [String : [AnyHashable : Any]] {
                strategies.forEach { key, strategy in
                    if strategy["type"] as? String == "oauth2" {
                        _oauthStrategies.append(["identifier": key, "strategy": strategy])
                    }
                }
                
            }
            //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            //    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
            //    NSMutableArray *oauthStrategies = [[NSMutableArray alloc] init];
            //    [strategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            //        if ([[obj objectForKey:@"type"] isEqualToString:@"oauth2"]) {
            //            [oauthStrategies addObject:@{@"identifier": key, @"strategy": obj}];
            //        }
            //    }];
            //    return oauthStrategies;
            return _oauthStrategies
        }
    }
    
    @objc public var strategies: [[String: Any]]? {
        get {
            var _strategies: [[String: Any]] = []
            if let defaultStrategies = UserDefaults.standard.serverAuthenticationStrategies as? [String : [AnyHashable : Any]] {
                defaultStrategies.forEach { key, strategy in
                    if key == "local" {
                        _strategies.append(["identifier": key, "strategy": strategy])
                    } else {
                        _strategies.insert(["identifier": key, "strategy": strategy], at: 0)
                    }
                }
                
            }
            //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            //    NSDictionary *defaultStrategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
            //    NSMutableArray *strategies = [[NSMutableArray alloc] init];
            //    [defaultStrategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            //        if ([key isEqualToString:@"local"]) {
            //            [strategies addObject:@{@"identifier": key, @"strategy": obj}];
            //        } else {
            //            [strategies insertObject:@{@"identifier": key, @"strategy": obj} atIndex:0];
            //        }
            //    }];
            //    return strategies;
            return _strategies
        }
    }
    
    @objc public static func checkServerCompatibility(api: [AnyHashable: Any]?) -> Bool {
        guard let serverCompatibilities = UserDefaults.standard.serverCompatibilities,
              let api = api,
              let apiVersion = api["version"] as? [AnyHashable: Any],
              let serverMajorVersion = apiVersion["major"] as? Int,
              let serverMinorVersion = apiVersion["minor"] as? Int else {
            return false
        }
        
        for compatibility in serverCompatibilities {
            if let serverCompatibilityMajorVersion = compatibility[MageServer.kServerMajorVersionKey],
               let serverCompatibilityMinorVersion = compatibility[kServerMinorVersionKey],
               serverCompatibilityMajorVersion == serverMajorVersion,
               serverCompatibilityMinorVersion <= serverMinorVersion
            {
                // server is compatible, save the version
                UserDefaults.standard.serverMajorVersion = serverMajorVersion
                UserDefaults.standard.serverMinorVersion = serverMinorVersion
                return true
            }
        }
        
        //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //    NSArray *serverCompatibilities  = [defaults arrayForKey:kServerCompatibilitiesKey];
        //
        //    for (NSDictionary *compatibility in serverCompatibilities) {
        //        NSNumber *serverCompatibilityMajorVersion = [compatibility valueForKey:kServerMajorVersionKey];
        //        NSNumber *serverCompatibilityMinorVersion = [compatibility valueForKey:kServerMinorVersionKey];
        //
        //        NSNumber *serverMajorVersion = [api valueForKeyPath:@"version.major"];
        //        NSNumber *serverMinorVersion = [api valueForKeyPath:@"version.minor"];
        //
        //        if ([serverCompatibilityMajorVersion intValue] == [serverMajorVersion intValue] && [serverCompatibilityMinorVersion intValue] <= [serverMinorVersion intValue]) {
        //            // server is compatible.  save the version
        //            [defaults setObject:[api valueForKeyPath:@"version.major"] forKey:@"serverMajorVersion"];
        //            [defaults setObject:[api valueForKeyPath:@"version.minor"] forKey:@"serverMinorVersion"];
        //            [defaults synchronize];
        //            return true;
        //        }
        //    }
        //    return false;
        return false
    }
    
    @objc public static func generateServerCompatibilityError(api: [AnyHashable: Any]?) -> NSError {
        if let api = api,
           let apiVersion = api["version"] as? [AnyHashable: Any],
           let serverMajorVersion = apiVersion["major"] as? Int,
           let serverMinorVersion = apiVersion["minor"] as? Int,
           let serverMicroVersion = apiVersion["micro"] as? Int
        {
            return NSError(domain: "MAGE", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "This version of the app is not compatible with version \(serverMajorVersion).\(serverMinorVersion).\(serverMicroVersion) of the server.  Please contact your MAGE administrator for more information."
            ])
        }
        if let api = api,
           let prettyApi = String(data: try! JSONSerialization.data(withJSONObject: api, options: .prettyPrinted), encoding: .utf8 )
        {
            return NSError(domain: "MAGE", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid server response \(prettyApi)"
            ])
        }
        return NSError(domain: "MAGE", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Invalid server response"
        ])
    }
    
    @objc public static func server(url: URL?, success: ((MageServer) -> Void)?, failure: ((NSError) -> Void)?) {
        guard let url = url, url.scheme != nil, url.host != nil else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let server = MageServer(url: url);
        // TODO: we need a way to force re-fetch the api in case strategies changed
        if (url.absoluteString == UserDefaults.standard.baseServerUrl && server.authenticationModules != nil) {
            success?(server)
            return
        }
        
        let manager = MageSessionManager.shared()
        let apiURL = "\(url.absoluteString)/api"
        let task = manager?.get_TASK(apiURL, parameters: nil, progress: nil, success: { task, response in
            if let dataResponse = response as? Data {
                if dataResponse.count == 0 {
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Empty API response received from server."]))
                    return
                }
                
                // try to turn it into a string in case it was HTML
                if let responseString = String(data: dataResponse, encoding: .utf8) {
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid API response received from server. \(responseString)"]))
                    return
                }
            }
            
            guard let apiResponse = response as? [AnyHashable : Any] else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Unknown API response received from server. \(task.response?.mimeType ?? "unkonwn mime type")"]))
                return
            }
            
            if MageServer.checkServerCompatibility(api: apiResponse) {
                UserDefaults.standard.baseServerUrl = url.absoluteString
            } else {
                failure?(MageServer.generateServerCompatibilityError(api: apiResponse))
                return
            }
            
            if let disclaimer = apiResponse[ApiKey.disclaimer.key] as? [String: Any] {
                UserDefaults.standard.showDisclaimer = disclaimer[DisclaimerKey.show.key] as? Bool ?? false
                UserDefaults.standard.disclaimerText = disclaimer[DisclaimerKey.text.key] as? String
                UserDefaults.standard.disclaimerTitle = disclaimer[DisclaimerKey.title.key] as? String
            }
            
            if let contactInfo = apiResponse[ApiKey.contactinfo.key] as? [String: Any] {
                UserDefaults.standard.contactInfoEmail = contactInfo[ContactInfoKey.email.key] as? String
                UserDefaults.standard.contactInfoPhone = contactInfo[ContactInfoKey.phone.key] as? String
            }
            // TODO: strategies value should be optional in case the server sends back something crazy
            if let authenticationStrategies = apiResponse[ApiKey.authenticationStrategies.key] as? [String: [AnyHashable: Any]] {
                UserDefaults.standard.authenticationStrategies = authenticationStrategies
                UserDefaults.standard.serverAuthenticationStrategies = authenticationStrategies
                var authenticationModules: [String: Any] = [:]
                for (authenticationStrategy, parameters) in authenticationStrategies {
                    if let authenticationModule = Authentication.authenticationModule(forStrategy: authenticationStrategy, parameters: parameters) {
                        authenticationModules[authenticationStrategy] = authenticationModule
                    }
                }
                if let oldLoginParameters = UserDefaults.standard.loginParameters, let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String, oldUrl == url.absoluteString, StoredPassword.retrieveStoredPassword() != nil {
                    authenticationModules["offline"] = Authentication.authenticationModule(forStrategy:"offline", parameters:nil)
                }
                
                server.authenticationModules = authenticationModules
                
                success?(server)
                return
            } else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid response from the MAGE server. \(apiResponse)"]))
                return
            }
        }, failure: { task, error in
            // check if the error indicates that the network is unavailable and return the offline authentication module
            let error = error as NSError
            if error.domain == NSURLErrorDomain
                && (error.code == NSURLErrorCannotConnectToHost
                    || error.code == NSURLErrorNetworkConnectionLost
                    || error.code == NSURLErrorNotConnectedToInternet
                    || error.code == NSURLErrorTimedOut
            ) {
                if let authentication: AuthenticationProtocol = Authentication.authenticationModule(forStrategy: "offline", parameters: nil), authentication.canHandleLogin(toURL: url.absoluteString) {
                    server.authenticationModules = ["offline":authentication]
                }
                success?(server)
            } else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to server.  Received error \(error.localizedDescription)"]))
            }
        })
        
        if let task = task {
            manager?.addTask(task)
        }
    }
    
    public init(url: URL) {
        super.init()
        if url.absoluteString != UserDefaults.standard.baseServerUrl {
            return
        }
        
        // TODO: strategies value should be optional in case the server sends back something crazy
        if let authenticationStrategies = UserDefaults.standard.authenticationStrategies {
            UserDefaults.standard.serverAuthenticationStrategies = authenticationStrategies
            var authenticationModules: [String: Any] = [:]
            for (authenticationStrategy, parameters) in authenticationStrategies {
                if let authenticationModule = Authentication.authenticationModule(forStrategy: authenticationStrategy, parameters: parameters) {
                    authenticationModules[authenticationStrategy] = authenticationModule
                }
            }
            if let oldLoginParameters = UserDefaults.standard.loginParameters, let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String, oldUrl == url.absoluteString, StoredPassword.retrieveStoredPassword() != nil {
                authenticationModules["offline"] = Authentication.authenticationModule(forStrategy:"offline", parameters:nil)
            }
            
            self.authenticationModules = authenticationModules
        }
    }

}

//@property (nonatomic, strong) NSDictionary *authenticationModules;
//
//- (instancetype) initWithURL: (NSURL *) url;
//+ (NSURL *) baseURL;
//- (BOOL) serverHasLocalAuthenticationStrategy;
//- (NSArray *) getOauthStrategies;
//- (NSArray *) getStrategies;
//
//+ (BOOL) checkServerCompatibility: (NSDictionary *) api;
//+ (NSError *) generateServerCompatibilityError: (NSDictionary *) api;
//+ (void) serverWithURL:(NSURL *) url success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure;
//+ (BOOL) isServerVersion5;
//+ (BOOL) isServerVersion6_0;
//
//
//#import "MageServer.h"
//#import "MageSessionManager.h"
//#import "LdapAuthentication.h"
//#import "LocalAuthentication.h"
//#import "ServerAuthentication.h"
//#import "IdpAuthentication.h"
//#import "StoredPassword.h"
//
//NSString * const kServerCompatibilitiesKey = @"serverCompatibilities";
//NSString * const kServerMajorVersionKey = @"serverMajorVersion";
//NSString * const kServerMinorVersionKey = @"serverMinorVersion";
//NSString * const kServerAuthenticationStrategiesKey = @"serverAuthenticationStrategies";
//
//NSString * const kBaseServerUrlKey = @"baseServerUrl";
//
//@implementation MageServer
//
//- (instancetype) initWithURL: (NSURL *) url {
//    if (self = [super init]) {
//
//        if (![url.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kBaseServerUrlKey]]) {
//            return self;
//        }
//
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSDictionary *authenticationStrategies = [defaults valueForKeyPath:@"authenticationStrategies"];
//
//        if (authenticationStrategies) {
//            NSMutableDictionary *authenticationModules = [[NSMutableDictionary alloc] init];
//            [defaults setObject:authenticationStrategies forKey:kServerAuthenticationStrategiesKey];
//            for (NSString *authenticationStrategy in authenticationStrategies) {
//                NSDictionary *parameters = [authenticationStrategies objectForKey:authenticationStrategy];
//                id authenticationModule = [Authentication authenticationModuleForStrategy:authenticationStrategy parameters:parameters];
//                if (authenticationModule) {
//                    [authenticationModules setObject:authenticationModule forKey:authenticationStrategy];
//                }
//            }
//
//            NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
//            if (oldLoginParameters != nil) {
//                NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
//                if ([oldUrl isEqualToString:[url absoluteString]] && [StoredPassword retrieveStoredPassword] != nil) {
//                    [authenticationModules setObject:[Authentication authenticationModuleForStrategy:@"offline" parameters:nil] forKey:@"offline"];
//                }
//            }
//
//            self.authenticationModules = authenticationModules;
//        }
//    }
//
//    return self;
//}
//
//+ (NSURL *) baseURL {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString *url = [defaults objectForKey:kBaseServerUrlKey];
//    return [NSURL URLWithString:url];
//}
//
//- (BOOL) serverHasLocalAuthenticationStrategy {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
//    return [strategies objectForKey:@"local"] != nil;
//}
//
//- (NSArray *) getStrategies {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *defaultStrategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
//    NSMutableArray *strategies = [[NSMutableArray alloc] init];
//    [defaultStrategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        if ([key isEqualToString:@"local"]) {
//            [strategies addObject:@{@"identifier": key, @"strategy": obj}];
//        } else {
//            [strategies insertObject:@{@"identifier": key, @"strategy": obj} atIndex:0];
//        }
//    }];
//    return strategies;
//}
//
//- (NSArray *) getOauthStrategies {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *strategies = [defaults objectForKey:kServerAuthenticationStrategiesKey];
//    NSMutableArray *oauthStrategies = [[NSMutableArray alloc] init];
//    [strategies enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        if ([[obj objectForKey:@"type"] isEqualToString:@"oauth2"]) {
//            [oauthStrategies addObject:@{@"identifier": key, @"strategy": obj}];
//        }
//    }];
//    return oauthStrategies;
//}
//
//+ (BOOL) checkServerCompatibility: (NSDictionary *) api {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSArray *serverCompatibilities  = [defaults arrayForKey:kServerCompatibilitiesKey];
//
//    for (NSDictionary *compatibility in serverCompatibilities) {
//        NSNumber *serverCompatibilityMajorVersion = [compatibility valueForKey:kServerMajorVersionKey];
//        NSNumber *serverCompatibilityMinorVersion = [compatibility valueForKey:kServerMinorVersionKey];
//
//        NSNumber *serverMajorVersion = [api valueForKeyPath:@"version.major"];
//        NSNumber *serverMinorVersion = [api valueForKeyPath:@"version.minor"];
//
//        if ([serverCompatibilityMajorVersion intValue] == [serverMajorVersion intValue] && [serverCompatibilityMinorVersion intValue] <= [serverMinorVersion intValue]) {
//            // server is compatible.  save the version
//            [defaults setObject:[api valueForKeyPath:@"version.major"] forKey:@"serverMajorVersion"];
//            [defaults setObject:[api valueForKeyPath:@"version.minor"] forKey:@"serverMinorVersion"];
//            [defaults synchronize];
//            return true;
//        }
//    }
//    return false;
//}
//
//+ (NSError *) generateServerCompatibilityError: (NSDictionary *) api {
//    if (!api || ![api valueForKey:@"version"]) {
//        return [[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid server response %@", api] forKey:NSLocalizedDescriptionKey]];
//    }
//    return [[NSError alloc] initWithDomain:@"MAGE" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"This version of the app is not compatible with version %@.%@.%@ of the server.  Please contact your MAGE administrator for more information.", [api valueForKeyPath:@"version.major"], [api valueForKeyPath:@"version.minor"], [api valueForKeyPath:@"version.micro"]]  forKey:NSLocalizedDescriptionKey]];
//}
//
//+ (BOOL) isServerVersion5 {
//    return [[NSUserDefaults standardUserDefaults] integerForKey:@"serverMajorVersion"] == 5;
//}
//
//+ (BOOL) isServerVersion6_0 {
//    return [[NSUserDefaults standardUserDefaults] integerForKey:@"serverMajorVersion"] == 6 && [[NSUserDefaults standardUserDefaults] integerForKey:@"serverMinorVersion"] == 0;
//}
//
//+ (void) serverWithURL:(NSURL *) url success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure {
//
//    if (!url || !url.scheme || !url.host) {
//        failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Invalid URL" forKey:NSLocalizedDescriptionKey]]);
//        return;
//    }
//
//    MageServer *server = [[MageServer alloc] initWithURL: url];
//    // TODO: we need a way to force re-fetch the api in case strategies changed
//    if ([url.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kBaseServerUrlKey]] && server.authenticationModules) {
//        success(server);
//        return;
//    }
//
//    MageSessionManager *manager = [MageSessionManager sharedManager];
//    NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
//    NSURLSessionDataTask *task = [manager GET_TASK:apiURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id response) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//        if ([response isKindOfClass:[NSData class]]) {
//            if (((NSData *)response).length == 0) {
//                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:@"Empty API response received from server." forKey:NSLocalizedDescriptionKey]]);
//                return;
//            }
//            // try to turn it into a string in case it was HTML
//            NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//            if (responseString) {
//                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Invalid API response received from server. %@", responseString] forKey:NSLocalizedDescriptionKey]]);
//                return;
//            }
//        }
//
//        if (![response isKindOfClass:[NSDictionary class]]) {
//            failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Unknown API response received from server. %@", task.response.MIMEType] forKey:NSLocalizedDescriptionKey]]);
//            return;
//        }
//
//        if ([MageServer checkServerCompatibility:response]) {
//            [defaults setObject:[url absoluteString] forKey:kBaseServerUrlKey];
//            [defaults synchronize];
//        } else {
//            failure([MageServer generateServerCompatibilityError:response]);
//            return;
//        }
//
//        NSDictionary *disclaimer = [response valueForKey:@"disclaimer"];
//        if (disclaimer) {
//            [defaults setObject:[disclaimer valueForKeyPath:@"show"] forKey:@"showDisclaimer"];
//            [defaults setObject:[disclaimer valueForKeyPath:@"text"] forKey:@"disclaimerText"];
//            [defaults setObject:[disclaimer valueForKeyPath:@"title"] forKey:@"disclaimerTitle"];
//        }
//
//        NSDictionary *contactinfo = [response valueForKey:@"contactinfo"];
//        if (contactinfo) {
//            [defaults setObject:[contactinfo valueForKeyPath:@"email"] forKey:@"contactInfoEmail"];
//            [defaults setObject:[contactinfo valueForKeyPath:@"phone"] forKey:@"contactInfoPhone"];
//        }
//
//        if (![response valueForKeyPath:@"authenticationStrategies"]) {
//            failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Invalid response from the MAGE server. %@", response] forKey:NSLocalizedDescriptionKey]]);
//            return;
//        }
//        [defaults setObject:[response valueForKeyPath:@"authenticationStrategies"] forKey:@"authenticationStrategies"];
//
//        NSMutableDictionary *authenticationModules = [[NSMutableDictionary alloc] init];
//        NSDictionary *authenticationStrategies = [response valueForKeyPath:@"authenticationStrategies"];
//        [defaults setObject:authenticationStrategies forKey:kServerAuthenticationStrategiesKey];
//        for (NSString *authenticationStrategy in authenticationStrategies) {
//            NSDictionary *parameters = [authenticationStrategies objectForKey:authenticationStrategy];
//            id authenticationModule = [Authentication authenticationModuleForStrategy:authenticationStrategy parameters:parameters];
//            if (authenticationModule) {
//                [authenticationModules setObject:authenticationModule forKey:authenticationStrategy];
//            }
//        }
//        NSDictionary *oldLoginParameters = [defaults objectForKey:@"loginParameters"];
//        if (oldLoginParameters != nil) {
//            NSString *oldUrl = [oldLoginParameters objectForKey:@"serverUrl"];
//            if ([oldUrl isEqualToString:[url absoluteString]] && [StoredPassword retrieveStoredPassword] != nil) {
//                [authenticationModules setObject:[Authentication authenticationModuleForStrategy:@"offline" parameters:nil] forKey:@"offline"];
//            }
//        }
//
//        server.authenticationModules = authenticationModules;
//
//        [defaults synchronize];
//
//        success(server);
//        return;
//    } failure:^(NSURLSessionTask *operation, NSError *error) {
//        // check if the error indicates that the network is unavailable and return the offline authentication module
//        if ([error.domain isEqualToString:NSURLErrorDomain]
//            && (error.code == NSURLErrorCannotConnectToHost
//                || error.code == NSURLErrorNetworkConnectionLost
//                || error.code == NSURLErrorNotConnectedToInternet
//                || error.code == NSURLErrorTimedOut
//                )) {
//                id<Authentication> authentication = [Authentication authenticationModuleForStrategy:@"offline" parameters:nil];
//                if ([authentication canHandleLoginToURL:[url absoluteString]]) {
//                    server.authenticationModules = [NSDictionary dictionaryWithObject:authentication forKey:@"offline"];
//                }
//                success(server);
//            } else {
//                failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: @"Failed to connect to server.  Received error %@", error.localizedDescription] forKey:NSLocalizedDescriptionKey]]);
//            }
//    }];
//
//    [manager addTask:task];
//
//}
//
//@end
