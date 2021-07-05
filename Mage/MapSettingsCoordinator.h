//
//  MapSettingsCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MDCContainerScheme.h>

@protocol MapSettingsCoordinatorDelegate
- (void) mapSettingsComplete:(NSObject *) coordinator;
@end

@interface MapSettingsCoordinator : NSObject

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController scheme: (id<MDCContainerScheming>) containerScheme;
- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController andSourceView: (UIView *) sourceView scheme: (id<MDCContainerScheming>) containerScheme;

@property (weak, nonatomic) id<MapSettingsCoordinatorDelegate> delegate;

- (void) start;

@end
