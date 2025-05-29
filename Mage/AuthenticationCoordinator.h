//
//  AuthenticationCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/6/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@class MageServer;

@protocol AuthenticationDelegate

- (void) authenticationSuccessful;
- (void) couldNotAuthenticate;
- (void) changeServerUrl;

@end

@interface AuthenticationCoordinator : NSObject

- (instancetype _Nullable) initWithNavigationController: (UINavigationController * _Nullable) navigationController andDelegate: (id<AuthenticationDelegate> _Nullable) delegate andScheme: (id<MDCContainerScheming> _Nullable) containerScheme context: (NSManagedObjectContext * _Nullable) context;
- (void) start:(MageServer * _Nullable) mageServer;
- (void) startLoginOnly;
- (void) showLoginViewForServer:(MageServer * _Nullable) mageServer;

@property (nonatomic, strong, readonly) MageServer * _Nullable server;
@end
