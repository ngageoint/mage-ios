//
//  MageServer.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Authentication.h"
#import "AFNetworkReachabilityManager.h"

@interface MageServer : NSObject

@property (nonatomic, strong) id<Authentication> authentication;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

+ (MageServer *) singleton;
+ (NSURL *) baseURL;

- (id) setupServerWithURL:(NSURL *) url success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure;

@end
