//
//  HttpManager.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface HttpManager : NSObject

extern NSString * const MAGETokenExpiredNotification;

+ (HttpManager *) singleton;
@property(strong) AFHTTPSessionManager *manager;

-(void) setToken: (NSString *) token;

-(void) clearToken;

-(AFHTTPRequestSerializer *) httpRequestSerializer;

@end
