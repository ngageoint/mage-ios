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

@end
