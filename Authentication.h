//
//  Authentication.h
//  mage-ios-sdk
//
//

#import "User.h"

typedef NS_ENUM(NSInteger, AuthenticationType) {
	LOCAL,
    SERVER
};

@protocol AuthenticationDelegate <NSObject>

@optional
- (void) authenticationWasSuccessful;
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