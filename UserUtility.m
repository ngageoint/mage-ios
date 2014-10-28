//
//  UserUtility.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/15/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "UserUtility.h"
#import <NSDate+DateTools.h>

@implementation UserUtility

+ (BOOL) isTokenExpired {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginParameters = [defaults objectForKey:@"loginParameters"];
    
    NSString *token = [loginParameters objectForKey:@"token"];
    if ([token length] == 0) {
        return YES;
    }
    
    NSDate *tokenExpirationDate = [loginParameters objectForKey:@"tokenExpirationDate"];
    if (tokenExpirationDate != nil && [tokenExpirationDate isKindOfClass:NSDate.class]) {
        NSDate *currentDate = [NSDate date];
        NSLog(@"current date %@ token expiration %@", currentDate, tokenExpirationDate);
        return [currentDate isLaterThan:tokenExpirationDate];
    }
    return YES;
}

+ (void) expireToken {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *loginParameters = [[defaults objectForKey:@"loginParameters"] mutableCopy];
    
    [loginParameters removeObjectForKey:@"token"];
    [loginParameters removeObjectForKey:@"tokenExpirationDate"];
    
    [defaults setObject:loginParameters forKey:@"loginParameters"];
    
    [defaults synchronize];
}

@end
