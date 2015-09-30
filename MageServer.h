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

+ (NSURL *) baseURL;

+ (void) serverWithURL:(NSURL *) url authenticationDelegate:(id<AuthenticationDelegate>) authenticationDelegate success:(void (^) ()) success  failure:(void (^) (NSError *error)) failure;

@end
