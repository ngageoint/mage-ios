//
//  MageServer.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MageServer : NSObject

+ (NSURL *) baseServerUrl;
+ (void) setBaseServerUrl:(NSString *) baseServerUrl;

@end
