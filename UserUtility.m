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
    
    NSString *token = [defaults stringForKey:@"token"];
    if ([token length] == 0) {
        return YES;
    }
    NSDate *tokenExpirationDate= [defaults objectForKey:@"tokenExpirationDate"];
    if (tokenExpirationDate != nil) {
        NSDate *currentDate = [NSDate date];
        return [currentDate isLaterThan:tokenExpirationDate];
    }
    return YES;
}

@end
