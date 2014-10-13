//
//  MageServer.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/13/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MageServer.h"

NSString * const kBaseServerUrlKey = @"baseServerUrl";

@implementation MageServer

+ (NSURL *) baseServerUrl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *baseServerUrl = [defaults stringForKey:kBaseServerUrlKey];
    return [NSURL URLWithString:baseServerUrl];
}

+ (void) setBaseServerUrl:(NSString *) baseServerUrl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:baseServerUrl forKey:kBaseServerUrlKey];
    [defaults synchronize];
}

@end
