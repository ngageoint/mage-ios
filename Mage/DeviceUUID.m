//
//  UID.m
//  Mage
//
//

#import "DeviceUUID.h"
#import <Foundation/Foundation.h>
#import <Security/Security.h>

@implementation DeviceUUID

static NSString * const kKeyChainService = @"mil.nga.giat.mage.uuid";


+ (NSUUID *) retrieveDeviceUUID {
	
	NSString *uuidString = [DeviceUUID retrieveUUIDFromKeyChain];
	
    // Failed to read the UUID from the KeyChain, so create a new UUID and store it
    if ([uuidString length] == 0) {
		uuidString = [DeviceUUID persistUUIDToKeyChain];
    }
	
    return [[NSUUID alloc] initWithUUIDString:uuidString];
}

+ (NSString *) retrieveUUIDFromKeyChain {
	NSString *uuidString = nil;
	
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
		// There is a UUID, so try to retrieve it
		NSDictionary *attributes = (__bridge_transfer NSDictionary *)attributesRef;
		NSMutableDictionary *valueQuery = [NSMutableDictionary dictionaryWithDictionary:attributes];
		
		[valueQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
		[valueQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
		
		CFTypeRef passwordDataRef = NULL;
		OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)valueQuery, &passwordDataRef);
		if (result == noErr) {
			NSData *passwordData = (__bridge_transfer NSData *)passwordDataRef;
			uuidString = [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding];
		}
	}
	
	return uuidString;
}

+ (NSString *) persistUUIDToKeyChain {
	// Generate the new UIID
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
	
	// Now store it in the KeyChain
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeyChainService,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        (__bridge id)kSecValueData: [uuidString dataUsingEncoding:NSUTF8StringEncoding]
    };
	
	OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
	if (result != noErr) {
		NSLog(@"ERROR: Couldn't add to the Keychain. Result = %d; Query = %@", (int)result, query);
		return nil;
	}
	
	return uuidString;
}

@end
