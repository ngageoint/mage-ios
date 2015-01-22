//
//  StoredPassword.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 1/20/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoredPassword : NSObject

+ (NSString *) retrieveStoredPassword;
+ (NSString *) persistPasswordToKeyChain: (NSString *) password;

@end
