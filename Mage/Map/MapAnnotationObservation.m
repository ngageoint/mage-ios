//
//  MapAnnotationObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapAnnotationObservation.h"

@interface MapAnnotationObservation ()

@property (nonatomic, weak) ObservationAnnotation *annotation;

@end

@implementation MapAnnotationObservation

-(instancetype) initWithObservation: (Observation *) observation andAnnotation: (ObservationAnnotation *) annotation{
    self = [super initWithObservation:observation];
    if(self){
        self.annotation = annotation;
    }
    return self;
}

-(ObservationAnnotation *) annotation{
    return _annotation;
}

-(void) removeFromMapView: (MKMapView *) mapView{
    [mapView removeAnnotation:_annotation];
}

-(void) hidden: (BOOL) hidden fromMapView: (MKMapView *) mapView{
    if(_view != nil){
        _view.hidden = hidden;
        _view.accessibilityElementsHidden = hidden;
        _view.enabled = !hidden;
    }
}

-(MKCoordinateRegion) viewRegionOfMapView: (MKMapView *) mapView{
    CLLocationDistance latitudeMeters = 2500;
    CLLocationDistance longitudeMeters = 2500;
    Observation *observation = [self observation];
    NSDictionary *properties = observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy * 2.5;  // double the radius w/ padding
        longitudeMeters = accuracy * 2.5; // double the radius w/ padding
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_annotation.coordinate, latitudeMeters, longitudeMeters);
    return [mapView regionThatFits:region];
}

@end
