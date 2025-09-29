//
//  Authentication.h
//  mage-ios-sdk
//
#import <Authentication/Authentication-Swift.h>

//typedef NS_ENUM(NSInteger, AuthenticationStatus) {
//    AUTHENTICATION_SUCCESS,
//    AUTHENTICATION_ERROR,
//    UNABLE_TO_AUTHENTICATE,
//    REGISTRATION_SUCCESS,
//    ACCOUNT_CREATION_SUCCESS
//};

@protocol AuthenticationProtocol <NSObject>

@required
- (instancetype) initWithParameters: (NSDictionary *) parameters;
- (NSDictionary *) parameters;
- (BOOL) canHandleLoginToURL: (NSString *) url;

// Now using swift enum
- (void) loginWithParameters: (NSDictionary *) loginParameters
                    complete:(void (^) (AuthenticationStatus authenticationStatus,
                                        NSString *errorString)) complete;

- (void) finishLogin:(void (^) (AuthenticationStatus authenticationStatus,
                                NSString *errorString,
                                NSString *errorDetail)) complete;
@end

@interface Authentication : NSObject
+ (id<AuthenticationProtocol>) authenticationModuleForStrategy: (NSString *)strategy
                                                    parameters:(NSDictionary *)parameters;

+ (BOOL)isLocalStrategy:(NSString *)strategy;
+ (BOOL)isLdapStrategy:(NSString *)strategy;
+ (BOOL)isIdpStrategy:(NSString *)strategy;
+ (BOOL)isOfflineStrategy:(NSString *)strategy;
@end
