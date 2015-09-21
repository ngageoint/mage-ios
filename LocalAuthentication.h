//
//  LocalAuthentication.h
//  mage-ios-sdk
//
//

#import "Authentication.h"
#import "User.h"

@interface LocalAuthentication : NSObject<Authentication>

- (void) loginWithParameters: (NSDictionary *) parameters;

@end