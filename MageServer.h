//
//  MageServer.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Authentication.h"

@interface MageServer : NSObject

@property (nonatomic, strong) id<Authentication> authentication;

+ (NSURL *) baseURL;

- (id) initWithURL:(NSURL *) url inManagedObjectContext: (NSManagedObjectContext *) context success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure;

@end
