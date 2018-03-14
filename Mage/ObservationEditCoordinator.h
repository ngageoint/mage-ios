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
#import "FormPickerViewController.h"
#import <CoreLocation/CoreLocation.h>

@protocol ObservationEditDelegate

- (void) editComplete: (Observation *) observation;
- (void) observationDeleted: (Observation *) observation;

@end

@interface ObservationEditCoordinator : NSObject <FormPickedDelegate>

- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andLocation: (WKBGeometry *) location andAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta;
- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andObservation: (Observation *) observation;
- (void) start;

@end
