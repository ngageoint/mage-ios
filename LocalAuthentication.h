//
//  LocalAuthentication.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Authentication.h"
#import "User.h"

@interface LocalAuthentication : NSObject<Authentication>

- (id) initWithURL: (NSURL *) url;

- (void) loginWithParameters: (NSDictionary *) parameters;

@property(strong) NSURL *baseURL;
@property(strong) NSDictionary *parameters;

@end