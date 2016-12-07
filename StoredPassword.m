//
//  StoredPassword.m
//  mage-ios-sdk
//
//

#import "StoredPassword.h"
#import <Security/Security.h>


@implementation StoredPassword

static NSString * const kKeyChainPassword = @"mil.nga.mage.password";
static NSString * const kKeyChainToken = @"mil.nga.mage.token";

+ (NSString *) retrieveStoredToken {
    return [StoredPassword retrieveStoredItemWithService:kKeyChainToken];
}

+ (NSString *) persistTokenToKeyChain: (NSString *) token {
    NSString *currentToken = [self retrieveStoredToken];
    return [StoredPassword persistItemToKeyChain:token withService:kKeyChainToken forCurrentItem:currentToken];
}

+ (NSString *) retrieveStoredPassword {
    return [StoredPassword retrieveStoredItemWithService:kKeyChainPassword];
}

+ (NSString *) persistPasswordToKeyChain: (NSString *) password {
    NSString *currentPassword = [self retrieveStoredPassword];
    return [StoredPassword persistItemToKeyChain:password withService:kKeyChainPassword forCurrentItem:currentPassword];
}

+ (NSString *) retrieveStoredItemWithService:(NSString *) service {
    
    NSString *item = nil;
    
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
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
        
        CFTypeRef dataRef = NULL;
        OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)valueQuery, &dataRef);
        if (result == noErr) {
            NSData *data = (__bridge_transfer NSData *) dataRef;
            item = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        }
    }
    
    return item;
}

+ (NSString *) persistItemToKeyChain: (NSString *) item withService: (NSString *) service forCurrentItem:(NSString *) currentItem {
    
    BOOL isMainThread = [NSThread isMainThread];
    
    // Now store it in the KeyChain
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                            (__bridge id)kSecValueData: [item dataUsingEncoding:NSUTF8StringEncoding]
                            };
    
    if (currentItem == nil) {
        
        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (result != noErr) {
            NSLog(@"ERROR: Couldn't add to the Keychain. Result = %d; Query = %@", (int)result, query);
            return nil;
        }
    } else {
        NSDictionary *query = @{
                                (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService: service,
                                (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                };
        
        NSDictionary *update = @{
                                 (__bridge id)kSecValueData: [item dataUsingEncoding:NSUTF8StringEncoding]
                                 };
        
        
        OSStatus result = SecItemUpdate((__bridge CFDictionaryRef) query, (__bridge CFDictionaryRef) update);
        if (result != noErr) {
            NSLog(@"ERROR: Couldn't add to the Keychain. Result = %d; Query = %@", (int)result, query);
            return nil;
        }
        
    }
    
    return item;
}


@end
