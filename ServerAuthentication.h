//
//  ServerAuthentication.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import "Authentication.h"

@interface ServerAuthentication : NSObject <Authentication>

- (void) loginWithParameters: (NSDictionary *) parameters;

@end
