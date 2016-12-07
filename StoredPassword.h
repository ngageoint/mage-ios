//
//  StoredPassword.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface StoredPassword : NSObject

+ (NSString *) retrieveStoredToken;
+ (NSString *) persistTokenToKeyChain: (NSString *) token;

+ (NSString *) retrieveStoredPassword;
+ (NSString *) persistPasswordToKeyChain: (NSString *) password;

@end
