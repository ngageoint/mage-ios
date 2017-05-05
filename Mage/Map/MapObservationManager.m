//
//  MapObservationManager.m
//  MAGE
//
//  Created by Brian Osborn on 5/2/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservationManager.h"
#import "WKBGeometryUtils.h"
#import "GPKGMapShapeConverter.h"
#import "MapShapeObservation.h"
#import "MapAnnotationObservation.h"

@interface MapObservationManager ()

@property (nonatomic, strong) MKMapView *mapView;

@end

@implementation MapObservationManager

-(instancetype) initWithMapView: (MKMapView *) mapView{
    self = [super init];
    if(self){
        self.mapView = mapView;
    }
    return self;
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation{
    return [self addToMapWithObservation:observation andHidden:NO];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation andHidden: (BOOL) hidden{
    
    MapObservation *observationShape = nil;
    
    WKBGeometry *geometry = [observation getGeometry];
    
    if(geometry.geometryType == WKB_POINT){
        // TODO Geometry annotation options?
        observationShape = [[MapAnnotationObservation alloc] initWithObservation:observation];
    } else{
        
        GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
        GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:geometry];
        // TODO Geometry shape options ?
        GPKGMapShape *mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:_mapView];
        
        observationShape = [MapShapeObservation createWithObservation:observation andMapShape:mapShape];
    }
    
    return observationShape;
}

-(MapAnnotation *) addShapeAnnotationAtLocation: (CLLocation *) location andHidden: (BOOL) hidden{
    // TODO Geometry add shape annotations?
    MapAnnotation *annotation = [[MapAnnotation alloc] init];
    [annotation setCoordinate:location.coordinate];
    [self.mapView addAnnotation:annotation];
    if(hidden){
        [self.mapView viewForAnnotation:annotation].hidden = hidden;
    }
    return annotation;
}


@end
