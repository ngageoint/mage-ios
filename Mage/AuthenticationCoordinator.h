//
//  AuthenticationCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/6/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MageServer.h"

@protocol AuthenticationDelegate

- (void) authenticationSuccessful;
- (void) couldNotAuthenticate;
- (void) changeServerUrl;

@end

@interface AuthenticationCoordinator : NSObject

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate: (id<AuthenticationDelegate>) delegate;
- (void) start:(MageServer *) mageServer;
- (void) startLoginOnly;
@end
