//
//  UserUtility.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/15/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "UserUtility.h"
#import <NSDate+DateTools.h>
#import "HttpManager.h"

@implementation UserUtility

+ (BOOL) isTokenExpired {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginParameters = [defaults objectForKey:@"loginParameters"];
    
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
    
    [loginParameters removeObjectForKey:@"tokenExpirationDate"];
    
    HttpManager *http = [HttpManager singleton];
    [http.manager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    [http.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    
    [defaults setObject:loginParameters forKey:@"loginParameters"];
    
    [defaults synchronize];
}

@end
