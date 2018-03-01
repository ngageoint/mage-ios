//
//  MageServer.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import "Authentication.h"
#import "AFNetworkReachabilityManager.h"

@interface MageServer : NSObject

@property (nonatomic, strong) NSDictionary *authenticationModules;

- (instancetype) initWithURL: (NSURL *) url;
+ (NSURL *) baseURL;
- (BOOL) serverHasLocalAuthenticationStrategy;
- (BOOL) serverHasGoogleAuthenticationStrategy;

+ (BOOL) checkServerCompatibility: (NSDictionary *) api;
+ (NSError *) generateServerCompatibilityError: (NSDictionary *) api;
+ (void) serverWithURL:(NSURL *) url success:(void (^) (MageServer *)) success  failure:(void (^) (NSError *error)) failure;

@end
