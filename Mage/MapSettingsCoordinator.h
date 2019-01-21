//
//  MapSettingsCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MapSettingsCoordinatorDelegate
- (void) mapSettingsComplete:(NSObject *) coordinator;
@end

@interface MapSettingsCoordinator : NSObject

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController;
- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController andSourceView: (UIView *) sourceView;

@property (weak, nonatomic) id<MapSettingsCoordinatorDelegate> delegate;

- (void) start;

@end
