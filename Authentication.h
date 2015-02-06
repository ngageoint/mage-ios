//
//  Authentication.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/3/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User.h"

typedef NS_ENUM(NSInteger, AuthenticationType) {
	LOCAL,
    SERVER
};

@protocol AuthenticationDelegate <NSObject>

@optional
- (void) authenticationWasSuccessful: (User *) user;
- (void) authenticationHadFailure;
- (void) registrationWasSuccessful;

@end

@protocol Authentication <NSObject>

@required

- (void) loginWithParameters: (NSDictionary *) parameters;
- (NSDictionary *) loginParameters;
- (BOOL) canHandleLoginToURL: (NSString *) url;

@property(nonatomic, retain) id<AuthenticationDelegate> delegate;

@end

@interface Authentication : NSObject

+ (id) authenticationWithType: (AuthenticationType) type;

@end