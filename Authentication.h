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
    UNABLE_TO_AUTHENTICATE,
    REGISTRATION_SUCCESS
};

@protocol Authentication <NSObject>

@required
- (instancetype) initWithParameters: (NSDictionary *) parameters;
- (NSDictionary *) loginParameters;
- (NSDictionary *) parameters;
- (BOOL) canHandleLoginToURL: (NSString *) url;
- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;

@end

@interface Authentication : NSObject

+ (id) authenticationModuleForType: (AuthenticationType) type;
+ (AuthenticationType) authenticationTypeFromString: (NSString *) value;
+ (NSString *) authenticationTypeToString: (AuthenticationType) authenticationType;

@end
