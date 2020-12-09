//
//  ObservationEditCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Observation.h"
#import "ObservationEditViewController.h"
#import <CoreLocation/CoreLocation.h>

@protocol ObservationEditDelegate

- (void) editCancel: (NSObject *) coordinator;
- (void) editComplete: (Observation *) observation coordinator: (NSObject *) coordinator;
- (void) observationDeleted: (Observation *) observation coordinator: (NSObject *) coordinator;

@end

@interface ObservationEditCoordinator_legacy : NSObject

- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andLocation: (SFGeometry *) location andAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta;
- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andObservation: (Observation *) observation;
- (void) start;

@end
