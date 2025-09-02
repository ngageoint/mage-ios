//
//  AuthenticationCoordinator+Testing.h
//  MAGE
//
//  Created by Brent Michalski on 3/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthenticationCoordinator.h"
#import "Authentication.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AuthenticationProtocol;

@interface AuthenticationCoordinator (Testing)

@property (nonatomic, strong, nullable) MageServer *server;

// Expose flows so tests don’t need to tap UI
- (void)disclaimerAgree;
- (void)disclaimerDisagree;
- (void)signupCanceled;
- (void)captchaCanceled;

- (void)getCaptcha:(NSString * _Nonnull)username
        completion:(void (^ _Nonnull)(NSString * _Nonnull captcha))completion;

- (void)signupWithParameters:(NSDictionary * _Nonnull)parameters
                  completion:(void (^ _Nonnull)(NSHTTPURLResponse * _Nonnull response))completion;

- (void)workOffline:(NSDictionary * _Nonnull)parameters
           complete:(void (^ _Nonnull)(AuthenticationStatus status,
                                       NSString * _Nullable errorString))complete;

- (void)unableToAuthenticate:(NSDictionary * _Nonnull)parameters
                    complete:(void (^ _Nonnull)(AuthenticationStatus status,
                                                NSString * _Nullable errorString))complete;

- (void)authenticationWasSuccessfulWithModule:(id<AuthenticationProtocol> _Nonnull)module;

- (void)loginWithParameters:(NSDictionary * _Nonnull)parameters
 withAuthenticationStrategy:(NSString * _Nonnull)authenticationStrategy
                   complete:(void (^ _Nonnull)(AuthenticationStatus status,
                                               NSString * _Nullable errorString))complete;

@end

NS_ASSUME_NONNULL_END

