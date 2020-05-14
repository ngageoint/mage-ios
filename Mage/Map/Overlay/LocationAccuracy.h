//
//  LocationAccuracy.h
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationAccuracy : MKCircle

@property (nonatomic, strong) NSDate *timestamp;

+(instancetype) locationAccuracyWithCenterCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius timestamp: (NSDate *) timestamp;

@end

NS_ASSUME_NONNULL_END
