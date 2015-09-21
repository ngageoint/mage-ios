//
//  StoredPassword.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface StoredPassword : NSObject

+ (NSString *) retrieveStoredPassword;
+ (NSString *) persistPasswordToKeyChain: (NSString *) password;

@end
