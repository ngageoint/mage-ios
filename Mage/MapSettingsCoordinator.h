//
//  MapSettingsCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppContainerScheming.h"

@protocol MapSettingsCoordinatorDelegate
- (void) mapSettingsComplete:(NSObject *) coordinator;
@end

@interface MapSettingsCoordinator : NSObject

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController scheme: (id<AppContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;
- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController andSourceView: (UIView *) sourceView scheme: (id<AppContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;

@property (weak, nonatomic) id<MapSettingsCoordinatorDelegate> delegate;

- (void) start;

@end
