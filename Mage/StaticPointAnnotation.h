//
//  StaticPointAnnotation.h
//  MAGE
//
//  Created by Dan Barela on 1/29/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface StaticPointAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (weak, nonatomic) NSDictionary *feature;
@property (weak, nonatomic) NSString *iconUrl;

- (id)initWithFeature:(NSDictionary *) feature;
- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;

@end
