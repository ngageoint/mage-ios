//
//  EventChooserCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/7/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAGE-Swift.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol EventChooserDelegate

- (void) eventChoosen: (Event *) event;

@end

@interface EventChooserCoordinator : NSObject

- (instancetype) initWithViewController: (UIViewController *) viewController andDelegate: (id<EventChooserDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme;
- (void) start;

@end
