//
//  MapAnnotationObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapAnnotationObservation.h"

@interface MapAnnotationObservation ()

@property (nonatomic, strong) ObservationAnnotation *annotation;

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

@end
