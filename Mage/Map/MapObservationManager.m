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
#import "StyledPolygon.h"
#import "StyledPolyline.h"

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
    return [self addToMapWithObservation:observation withGeometry:[observation getGeometry] andHidden:hidden];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (WKBGeometry *) geometry{
    return [self addToMapWithObservation:observation withGeometry:geometry andHidden:NO];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (WKBGeometry *) geometry andHidden: (BOOL) hidden{
    
    MapObservation *observationShape = nil;
    
    if(geometry.geometryType == WKB_POINT){
        
        ObservationAnnotation *annotation = [[ObservationAnnotation alloc] initWithObservation:observation andGeometry:geometry];
        [_mapView addAnnotation:annotation];
        
        observationShape = [[MapAnnotationObservation alloc] initWithObservation:observation andAnnotation:annotation];
    } else{
        
        GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
        GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:geometry];
        switch(shape.shapeType){
            case GPKG_MST_POLYLINE:
                {
                    StyledPolyline *styledPolyline = [StyledPolyline createWithPolyline:(MKPolyline *)shape.shape];
                    [self setPolylineStyle: styledPolyline];
                    [shape setShape:styledPolyline];
                }
                break;
            case GPKG_MST_POLYGON:
                {
                    StyledPolygon *styledPolygon = [StyledPolygon createWithPolygon:(MKPolygon *)shape.shape];
                    [self setPolygonStyle: styledPolygon];
                    [shape setShape:styledPolygon];
                }
                break;
            default:
                [NSException raise:@"Unsupported Shape Type" format:@"Unsupported shape type: %u", shape.shapeType];
        }

        GPKGMapShape *mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:_mapView];
        
        observationShape = [MapShapeObservation createWithObservation:observation andMapShape:mapShape];
    }
    
    return observationShape;
}

-(MapAnnotation *) addShapeAnnotationAtLocation: (CLLocationCoordinate2D) location forObservation: (Observation *) observation andHidden: (BOOL) hidden{
    ObservationAnnotation *annotation = [[ObservationAnnotation alloc] initWithObservation:observation andLocation:location];
    [annotation setCoordinate:location];
    [self.mapView addAnnotation:annotation];
    if(hidden){
        [self.mapView viewForAnnotation:annotation].hidden = hidden;
    }
    return annotation;
}

-(void) setPolylineStyle: (StyledPolyline *) polyline{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [polyline lineColorWithHexString:[defaults stringForKey:@"polyline_color"] andAlpha:[defaults integerForKey:@"polyline_color_alpha"] / 255.0];
    [polyline setLineWidth:1.0];
}

-(void) setPolygonStyle: (StyledPolygon *) polygon{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [polygon lineColorWithHexString:[defaults stringForKey:@"polygon_color"] andAlpha:[defaults integerForKey:@"polygon_color_alpha"] / 255.0];
    [polygon fillColorWithHexString:[defaults stringForKey:@"polygon_fill_color"] andAlpha:[defaults integerForKey:@"polygon_fill_color_alpha"] / 255.0];
    [polygon setLineWidth:1.0];
}

@end
