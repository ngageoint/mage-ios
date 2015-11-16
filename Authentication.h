//
//  Authentication.h
//  mage-ios-sdk
//
//

#import "User.h"

typedef NS_ENUM(NSInteger, AuthenticationType) {
	LOCAL,
    SERVER,
    GOOGLE
};

typedef NS_ENUM(NSInteger, AuthenticationStatus) {
    AUTHENTICATION_SUCCESS,
    AUTHENTICATION_ERROR,
    REGISTRATION_SUCCESS
};

@protocol Authentication <NSObject>

@required
- (NSDictionary *) loginParameters;
- (BOOL) canHandleLoginToURL: (NSString *) url;
- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus)) success;

@end

@interface Authentication : NSObject

+ (id) authenticationModuleForType: (AuthenticationType) type;
+ (AuthenticationType) authenticationTypeFromString: (NSString *) value;
+ (NSString *) authenticationTypeToString: (AuthenticationType) authenticationType;

@end