//
//  MageServer.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import "Authentication.h"
#import "AFNetworkReachabilityManager.h"

@interface MageServer : NSObject

@property (nonatomic, strong) id<Authentication> authentication;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

+ (MageServer *) singleton;
+ (NSURL *) baseURL;

- (id) setupServerWithURL:(NSURL *) url success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure;

@end
