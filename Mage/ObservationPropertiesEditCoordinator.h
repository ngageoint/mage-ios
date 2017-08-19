//
//  ObservationPropertiesEditCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 8/17/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Observation.h>

@protocol ObservationPropertiesEditDelegate <NSObject>

- (void) propertiesEditCanceled;
- (void) propertiesEditComplete;

@end

@interface ObservationPropertiesEditCoordinator : NSObject

- (instancetype) initWithObservation: (Observation *) observation  andNewObservation: (BOOL) newObservation andNavigationController: (UINavigationController *) navigationController andDelegate: (id<ObservationPropertiesEditDelegate>) delegate;
- (void) start;

@end
