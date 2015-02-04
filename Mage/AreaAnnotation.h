//
//  AreaAnnotation.h
//  MAGE
//
//  Created by Dan Barela on 2/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AreaAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;
- (void) setTitle:(NSString *)title;

@end
