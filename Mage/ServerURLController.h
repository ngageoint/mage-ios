//
//  ServerURLController.h
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol ServerURLDelegate

- (void) setServerURL: (NSURL *) url;
- (void) cancelSetServerURL;

@end

@interface ServerURLController : UIViewController

- (instancetype) initWithDelegate: (id<ServerURLDelegate>) delegate andScheme: (id<MDCContainerScheming>) containerScheme;
- (instancetype) initWithDelegate: (id<ServerURLDelegate>) delegate andError: (NSString *) error andScheme: (id<MDCContainerScheming>) containerScheme;
- (void) showError: (NSString *) error;

@end
