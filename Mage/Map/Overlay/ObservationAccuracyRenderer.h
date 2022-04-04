//
//  AccuracyOverlayView.h
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObservationAccuracyRenderer : MKCircleRenderer

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end

NS_ASSUME_NONNULL_END
