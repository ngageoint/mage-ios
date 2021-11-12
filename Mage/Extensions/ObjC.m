//
//  ObjC.m
//  MAGE
//
//  Created by Daniel Barela on 11/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObjC.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (exception.userInfo != NULL) {
            userInfo = [[NSMutableDictionary alloc] initWithDictionary:exception.userInfo];
        }
        if (exception.reason != nil) {
            if (![userInfo.allKeys containsObject:NSLocalizedFailureReasonErrorKey]) {
                [userInfo setObject:exception.reason forKey:NSLocalizedFailureReasonErrorKey];
            }
        }
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

@end
