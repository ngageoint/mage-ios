//
//  AccuracyOverlayView.h
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MAGE-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationAccuracyRenderer : MKCircleRenderer

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end

NS_ASSUME_NONNULL_END
