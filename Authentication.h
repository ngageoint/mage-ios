//
//  Authentication.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 3/3/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User.h"

typedef NS_ENUM(NSInteger, AuthenticationType) {
	LOCAL
};

@protocol AuthenticationDelegate <NSObject>

@optional
- (void) authenticationWasSuccessful: (User *) user;
- (void) authenticationHadFailure;

@end

@protocol Authentication <NSObject>

@required
- (id<Authentication>) initWithURL: (NSURL *) url inManagedObjectContext: (NSManagedObjectContext *) context;

- (void) loginWithParameters: (NSDictionary *) parameters;

@property(nonatomic, retain) id<AuthenticationDelegate> delegate;

@end

@interface Authentication : NSObject

+ (id) authenticationWithType: (AuthenticationType) type url: (NSURL *) url inManagedObjectContext: (NSManagedObjectContext *) context;

@end