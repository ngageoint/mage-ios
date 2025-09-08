//
//  MageAuthAPI.h
//  MAGE
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MageAuthAPI : NSObject

/// PUT `/api/users/myself/password`
+ (void)changePasswordWithCurrent:(NSString *)current
                      newPassword:(NSString *)newPassword
               confirmNewPassword:(NSString *)confirmNewPassword
                       completion:(void(^)(NSHTTPURLResponse * _Nullable http,
                                           NSData * _Nullable errorBody,
                                           NSError * _Nullable error))completion;

+ (void)requestSignupCaptchaForUsername:(NSString *)username
                             background:(NSString *)backgroundHex
                             completion:(void(^)(NSString * _Nullable token,
                                                 NSString * _Nullable captchaBase64,
                                                 NSError * _Nullable error))completion;

+ (void)completeSignupWithParameters:(NSDictionary *)parameters
                               token:(NSString *)token
                          completion:(void(^)(NSHTTPURLResponse * _Nullable http,
                                              NSData * _Nullable errorBody,
                                              NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
