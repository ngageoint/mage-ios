//
//  HttpManager.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/9/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface HttpManager : NSObject

+ (HttpManager *) singleton;
@property(strong) AFHTTPRequestOperationManager *manager;
@property(strong) AFHTTPSessionManager *sessionManager;

@end
