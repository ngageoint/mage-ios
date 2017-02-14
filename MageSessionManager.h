//
//  MageSessionManager.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface MageSessionManager : AFHTTPSessionManager

extern NSString * const MAGETokenExpiredNotification;

+ (MageSessionManager *) manager;

-(void) setToken: (NSString *) token;

-(void) clearToken;

-(AFHTTPRequestSerializer *) httpRequestSerializer;

@end
