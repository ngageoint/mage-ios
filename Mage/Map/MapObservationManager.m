//
//  MapObservationManager.m
//  MAGE
//
//  Created by Brian Osborn on 5/2/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservationManager.h"
#import "SFGeometryUtils.h"
#import "GPKGMapShapeConverter.h"
#import "MapShapeObservation.h"
#import "MapAnnotationObservation.h"
#import "ObservationShapeStyle.h"
#import "ObservationShapeStyleParser.h"
#import "MAGE-Swift.h"

@interface MapObservationManager ()

@property (nonatomic, strong) MKMapView *mapView;

@end

@implementation MapObservationManager

-(instancetype) initWithMapView: (MKMapView *) mapView {
    self = [super init];
    if(self){
        self.mapView = mapView;
    }
    return self;
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation{
    return [self addToMapWithObservation:observation andHidden:NO];
}

-(MapObservation *) addToMapWithObservation:(Observation *)observation andAnimateDrop: (BOOL) animateDrop {
    return [self addToMapWithObservation:observation withGeometry:observation.geometry andHidden:NO andAnimateDrop:animateDrop];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation andHidden: (BOOL) hidden {
    return [self addToMapWithObservation:observation withGeometry:observation.geometry andHidden:hidden andAnimateDrop:YES];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (SFGeometry *) geometry {
    return [self addToMapWithObservation:observation withGeometry:geometry andHidden:NO andAnimateDrop:YES];
}

-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (SFGeometry *) geometry andHidden: (BOOL) hidden andAnimateDrop: (BOOL) animateDrop {
    
    MapObservation *observationShape = nil;
    
    if(geometry.geometryType == SF_POINT){
        
        ObservationAnnotation *annotation = [[ObservationAnnotation alloc] initWithObservation:observation geometry:geometry];
        annotation.view.layer.zPosition = [observation.timestamp timeIntervalSinceReferenceDate];
        annotation.animateDrop = animateDrop;
        [_mapView addAnnotation:annotation];
        
//        observationShape = [[MapAnnotationObservation alloc] initWithObservation:observation andAnnotation:annotation];
    } else{
        
        ObservationShapeStyle *style = [ObservationShapeStyleParser styleOfObservation: observation];
        
        GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
        GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:geometry];
        [shapeConverter close];
        switch(shape.shapeType){
            case GPKG_MST_POLYLINE:
                {
                    StyledPolyline *styledPolyline = [StyledPolyline createWithPolyline:(MKPolyline *)shape.shape];
                    [self setStyledPolyline: styledPolyline withStyle:style];
                    [shape setShape:styledPolyline];
                }
                break;
            case GPKG_MST_POLYGON:
                {
                    StyledPolygon *styledPolygon = [StyledPolygon createWithPolygon:(MKPolygon *)shape.shape];
                    [self setStyledPolygon: styledPolygon withStyle:style];
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
    ObservationAnnotation *annotation = [[ObservationAnnotation alloc] initWithObservation:observation location:location];
    [annotation setCoordinate:location];
    [self.mapView addAnnotation:annotation];
    if(hidden){
        [self.mapView viewForAnnotation:annotation].hidden = hidden;
    }
    return annotation;
}

-(void) setStyledPolyline: (StyledPolyline *) polyline withStyle: (ObservationShapeStyle *) style{
    [polyline setLineWidth:style.lineWidth];
    [polyline setLineColor:style.strokeColor];
}

-(void) setStyledPolygon: (StyledPolygon *) polygon withStyle: (ObservationShapeStyle *) style{
    [polygon setLineWidth:style.lineWidth];
    [polygon setLineColor:style.strokeColor];
    [polygon setFillColor:style.fillColor];
}

@end
