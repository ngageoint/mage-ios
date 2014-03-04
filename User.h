//
//  User
//  mage-ios-sdk
//
//  Created by Billy Newman on 2/24/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

- (id) initWithJSON: (NSDictionary *) json;

@property(strong) NSString *token;
@property(strong) NSString *username;
@property(strong) NSString *firstName;
@property(strong) NSString *lastName;
@property(strong) NSString *email;
@property(strong) NSArray *phoneNumbers;

@end