//
//  ObservationRoutes.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteMethod.h"
#import "Observation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationRoutes : NSObject

+ (instancetype) singleton;

- (RouteMethod *) pull: (NSNumber *) eventId;
- (RouteMethod *) deleteRoute: (Observation *) observation;
- (RouteMethod *) createId: (Observation *) observation;
- (RouteMethod *) pushFavorite: (ObservationFavorite *) observationFavorite;
- (RouteMethod *) pushImportant: (ObservationImportant *) important;

@end

NS_ASSUME_NONNULL_END
