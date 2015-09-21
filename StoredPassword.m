//
//  StoredPassword.m
//  mage-ios-sdk
//
//

#import "StoredPassword.h"
#import <Security/Security.h>

@implementation StoredPassword

static NSString * const kKeyChainService = @"mil.nga.giat.mage.pass";

+ (NSString *) retrieveStoredPassword{
    
    NSString *passwordString = nil;
    
    // Check to see if a UUID is stored in the KeyChain
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: kKeyChainService,
                            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                            (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue
                            };
    
    CFTypeRef attributesRef = NULL;
    OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)query, &attributesRef);
    if (result == noErr) {
        NSDictionary *attributes = (__bridge_transfer NSDictionary *)attributesRef;
        NSMutableDictionary *valueQuery = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        [valueQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [valueQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        
        CFTypeRef passwordDataRef = NULL;
        OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)valueQuery, &passwordDataRef);
        if (result == noErr) {
            NSData *passwordData = (__bridge_transfer NSData *)passwordDataRef;
            passwordString = [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding];
        }
    }
    
    return passwordString;
}

+ (NSString *) persistPasswordToKeyChain: (NSString *) password {
    
    // Now store it in the KeyChain
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: kKeyChainService,
                            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                            (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding]
                            };
    NSString *currentPw = [self retrieveStoredPassword];
    if (currentPw == nil) {
        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (result != noErr) {
            NSLog(@"ERROR: Couldn't add to the Keychain. Result = %d; Query = %@", (int)result, query);
            return nil;
        }
    } else {
        SecItemDelete((__bridge CFDictionaryRef)query);
        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (result != noErr) {
            NSLog(@"ERROR: Couldn't add to the Keychain. Result = %d; Query = %@", (int)result, query);
            return nil;
        }
    }
    
    return password;
}


@end
