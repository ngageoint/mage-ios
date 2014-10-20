//
//  LocalAuthentication.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Authentication.h"
#import "User.h"

@interface LocalAuthentication : NSObject<Authentication>

- (id) initWithManagedObjectContext:(NSManagedObjectContext *) context;

- (void) loginWithParameters: (NSDictionary *) parameters;

@end