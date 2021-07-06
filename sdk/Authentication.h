//
//  Authentication.h
//  mage-ios-sdk
//

#import "User.h"

typedef NS_ENUM(NSInteger, AuthenticationStatus) {
    AUTHENTICATION_SUCCESS,
    AUTHENTICATION_ERROR,
    UNABLE_TO_AUTHENTICATE,
    REGISTRATION_SUCCESS,
    ACCOUNT_CREATION_SUCCESS
};

@protocol Authentication <NSObject>

@required
- (instancetype) initWithParameters: (NSDictionary *) parameters;
- (NSDictionary *) parameters;
- (BOOL) canHandleLoginToURL: (NSString *) url;
- (void) loginWithParameters: (NSDictionary *) loginParameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
@end

@interface Authentication : NSObject
+ (id) authenticationModuleForStrategy: (NSString *) strategy parameters:(NSDictionary *) parameters;
@end
