//
//  MageServer.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MageServer.h"
#import "HttpManager.h"

NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

+ (NSURL *) baseURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:kBaseServerUrlKey];
    return [NSURL URLWithString:url];
}

- (id) initWithURL:(NSURL *) url success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[url absoluteString] forKey:kBaseServerUrlKey];
        [defaults synchronize];
        
        HttpManager *http = [HttpManager singleton];
        NSString *apiURL = [NSString stringWithFormat:@"%@/%@", [url absoluteString], @"api"];
        [http.manager GET:apiURL parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
            // TODO at some point we could read the server response and create the correct authentication module.
            // For now just create the local (username/password) authentication module.
            self.authentication = [Authentication authenticationWithType:LOCAL];
            
            // TODO check server version
            
            success();
        } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
            failure(error);
        }];
    }
    
    return self;
}

@end
