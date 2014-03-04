//
//  LocalAuthentication.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Authentication.h"
#import "User.h"

@protocol LoginDelegate <NSObject>

@optional
- (void) loginSuccess: (User *) token;
- (void) loginFailure;

@end

@interface LocalAuthentication : NSObject<Authentication>

- (id) initWithURL: (NSURL *) baseURL andParameters: (NSDictionary *) parameters;

- (void) login;

@property(strong) NSURL *baseURL;
@property(strong) NSDictionary *parameters;
@property(assign) id<LoginDelegate> delegate;

@end
