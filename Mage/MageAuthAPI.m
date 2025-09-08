//
//  MageAuthAPI.m
//  MAGE
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageAuthAPI.h"
#import "MageSessionManager.h"
//#import "MAGE-Bridging-Header.h"
#import "MAGE-Swift.h"

@implementation MageAuthAPI

+ (void)changePasswordWithCurrent:(NSString *)current
                      newPassword:(NSString *)newPassword
               confirmNewPassword:(NSString *)confirmNewPassword
                       completion:(void (^)(NSHTTPURLResponse * _Nullable, NSData * _Nullable, NSError * _Nullable))completion
{
    NSURL *base = [MageServer baseURL];
    if(!base) {
        if (completion) completion(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey:@"Missing base URL"}]);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", base.absoluteString, @"api/users/myself/password"];
    
    NSDictionary *parameters = @{
        @"password": current ?: @"",
        @"newPassword": newPassword ?: @"",
        @"newPasswordConfirm": confirmNewPassword ?: @""
    };
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"PUT"
                                                                      URLString:urlString
                                                                     parameters:parameters
                                                                          error:nil];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request
                                               uploadProgress:nil
                                             downloadProgress:nil
                                            completionHandler:^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error)
                                  {
        if (completion) {
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            NSData *body = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            completion(http, body, error);
        }
    }];
    
    [manager addTask: task];
}


+ (void)requestSignupCaptchaForUsername:(NSString *)username
                             background:(NSString *)backgroundHex
                             completion:(void (^)(NSString * _Nullable,
                                                  NSString * _Nullable,
                                                  NSError * _Nullable))completion
{
    NSURL *base = [MageServer baseURL];
    if (!base) {
        if (completion) completion(nil, nil,
                                   [NSError errorWithDomain: NSURLErrorDomain code:NSURLErrorBadURL
                                                   userInfo:@{NSLocalizedDescriptionKey:@"Missing base URL"}]);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", base.absoluteString, @"api/users/signups"];
    NSDictionary *params = @{ @"username": username ?: @"", @"background": backgroundHex ?: @"#FFFFFF" };
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSMutableURLRequest *req = [manager.requestSerializer requestWithMethod:@"POST"
                                                                  URLString:urlString
                                                                 parameters:params
                                                                      error:nil];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil
                                            completionHandler:^(NSURLResponse * _Nonnull response,
                                                                id  _Nullable responseObject,
                                                                NSError * _Nullable error)
                                  {
        void (^finish)(NSString*, NSString*, NSError*) = ^(NSString *t, NSString *c, NSError *e) {
            // Hop to main so SwiftUI state updates are safe
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(t, c, e); });
        };
        
        if (error) { finish(nil, nil, error); return ; }
        
        id obj = responseObject;
        
        if([obj isKindOfClass:[NSData class]]) {
            NSError *jsonErr = nil;
            id parsed = [NSJSONSerialization JSONObjectWithData:(NSData *)obj options:0 error:&jsonErr];
            if (jsonErr) { finish(nil, nil, jsonErr); return ; }
            obj = parsed ?: @{};
        }
        
        if (![obj isKindOfClass:[NSDictionary class]]) {
            NSError *e = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotParseResponse
                                         userInfo:@{NSLocalizedDescriptionKey:@"Unexpected signup captcha response"}];
            finish(nil, nil, e);
            return;
        }

        NSDictionary *dict = (NSDictionary *)obj;
        NSString *token = [dict objectForKey:@"token"];
        NSString *captcha = [dict objectForKey:@"captcha"];
        
        if (token.length == 0 || captcha.length == 0) {
            NSError *e = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotParseResponse
                                         userInfo:@{NSLocalizedDescriptionKey:@"Missing captcha or token"}];
            finish(nil, nil, e);
            return;
        }
        finish(token, captcha, nil);
    }];
    
    [manager addTask:task];
}

+ (void)completeSignupWithParameters:(NSDictionary *)parameters
                               token:(NSString *)token
                          completion:(void (^)(NSHTTPURLResponse * _Nullable http,
                                               NSData * _Nullable errorBody,
                                               NSError * _Nullable error))completion
{
    NSURL *base = [MageServer baseURL];
    if (!base) { if (completion) completion(nil, nil,
                                            [NSError errorWithDomain: NSURLErrorDomain code:NSURLErrorBadURL
                                                            userInfo:@{NSLocalizedDescriptionKey:@"Missing base URL"}]); return; }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", base.absoluteString, @"api/users/signups/verifications"];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSMutableURLRequest *req = [manager.requestSerializer requestWithMethod:@"POST"
                                                                  URLString:urlString
                                                                 parameters:parameters
                                                                      error:nil];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", token ?: @""] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil
                                            completionHandler:^(NSURLResponse * _Nonnull response,
                                                                id  _Nullable responseObject,
                                                                NSError * _Nullable error)
                                  {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSData *body = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (completion) completion(http, body, error);
    }];

    [manager addTask: task];
}

@end
