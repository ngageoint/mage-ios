//
//  AuthenticationCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/6/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol AuthenticationDelegate

- (void) authenticationSuccessful;
- (void) couldNotAuthenticate;

@end

@interface AuthenticationCoordinator : NSObject

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate: (id<AuthenticationDelegate>) delegate andScheme: (id<MDCContainerScheming>) containerScheme;
- (void) start;
- (void) startLoginOnly;

@end
