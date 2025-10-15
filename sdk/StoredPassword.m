//
//  StoredPassword.m
//  mage-ios-sdk
//
//

#import "StoredPassword.h"
#import <Security/Security.h>


@implementation StoredPassword

static NSString * const kKeyChainPassword   = @"mil.nga.mage.password";
static NSString * const kKeyChainToken      = @"mil.nga.mage.token";

#pragma mark - Public API

+ (NSString *) retrieveStoredToken {
    return [StoredPassword retrieveStoredItemWithService:kKeyChainToken];
}

+ (NSString *) persistTokenToKeyChain: (NSString *) token {
    NSString *currentToken = [self retrieveStoredToken];
    return [StoredPassword persistItemToKeyChain:token withService:kKeyChainToken forCurrentItem:currentToken];
}

+ (void) clearToken {
    [StoredPassword deleteItemWithService:kKeyChainToken];
}

+ (void) clearPassword {
    [StoredPassword deleteItemWithService:kKeyChainPassword];
}

+ (NSString *) retrieveStoredPassword {
    return [StoredPassword retrieveStoredItemWithService:kKeyChainPassword];
}

+ (NSString *) persistPasswordToKeyChain: (NSString *) password {
    NSString *currentPassword = [self retrieveStoredPassword];
    return [StoredPassword persistItemToKeyChain:password withService:kKeyChainPassword forCurrentItem:currentPassword];
}

#pragma mark - Internals

+ (NSString *) retrieveStoredItemWithService:(NSString *) service {
    NSString *item = nil;
    
    // Single-pass read: ask directly for the data.
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                            (__bridge id)kSecReturnAttributes:(__bridge id)kCFBooleanTrue
                            };
    
    CFTypeRef attributesRef = NULL;
    OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)query, &attributesRef);
    if (result == errSecSuccess) {
        NSDictionary *attributes = (__bridge_transfer NSDictionary *)attributesRef;
        
        NSMutableDictionary *valueQuery = [NSMutableDictionary dictionaryWithDictionary:attributes];
        valueQuery[(__bridge id) kSecClass]         = (__bridge id)kSecClassGenericPassword;
        valueQuery[(__bridge id) kSecReturnData]    = (__bridge id)kCFBooleanTrue;
        
        CFTypeRef dataRef = NULL;
        OSStatus dataResult = SecItemCopyMatching((__bridge CFDictionaryRef)valueQuery, &dataRef);
        if (dataResult == errSecSuccess) {
            NSData *data = (__bridge_transfer NSData *)dataRef;
            item = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        }
    }
    
    return item;
}

+ (NSString *) persistItemToKeyChain: (NSString *) item
                         withService: (NSString *) service
                      forCurrentItem:(NSString *) currentItem {
        
    // Attributes for a *new* item
    NSDictionary *addQuery = @{
                            (__bridge id)kSecClass:             (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService:       service,
                            (__bridge id)kSecAttrAccessible:    (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                            (__bridge id)kSecValueData:         [item dataUsingEncoding:NSUTF8StringEncoding]
                            };
    
    if (currentItem == nil) {
        
        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
        if (result == errSecDuplicateItem) {
            // If somehow it already exists, fall back to update path
            NSDictionary *match = @{
                (__bridge id)kSecClass:         (__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrService:   service
            };
            
            NSDictionary *update = @{
                (__bridge id)kSecValueData: [item dataUsingEncoding:NSUTF8StringEncoding]
            };
            
            result = SecItemUpdate((__bridge CFDictionaryRef)match, (__bridge CFDictionaryRef)update);
        }
            
        if (result != errSecSuccess) {
            NSLog(@"[StoredPassword] Keychain add/update failed: %d; service=%@", (int)result, service);
            return nil;
        }
    } else {
        // IMPORTANT: do *not* include kSecAttrAccessible in the match query.
        NSDictionary *match = @{
            (__bridge id)kSecClass:         (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:   service
        };
        NSDictionary *update = @{
            (__bridge id)kSecValueData:     [item dataUsingEncoding:NSUTF8StringEncoding]
        };

        OSStatus result = SecItemUpdate((__bridge CFDictionaryRef)match, (__bridge CFDictionaryRef)update);
        if(result == errSecItemNotFound) {
            // If not found, add it fresh with the secure accessibility attribute
            OSStatus addResult = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
            if (addResult != errSecSuccess) {
                NSLog(@"[StoredPassword] Keychain add after not-found failed: %d; service=%@", (int)addResult, service);
                return nil;
            }
        } else if (result != errSecSuccess) {
            NSLog(@"[StoredPassword] Keychain update failed: %d; service=%@", (int)result, service);
            return nil;
        }
    }
    
    return item;
}

+ (void) deleteItemWithService: (NSString *) service {
    // IMPORTANT: do *not* include kSecAttrAccessible in the match query.
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service
    };
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)query);
    
    // Treat "not found" as success (nothing to delete)
    if (result != errSecSuccess && result != errSecItemNotFound) {
        NSLog(@"[StoredPassword] Keychain delete failed: %d; service=%@", (int)result, service);
    }
}

@end
