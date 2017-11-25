//
//  MapObservations.m
//  MAGE
//
//  Created by Brian Osborn on 5/2/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservations.h"
#import "MapUtils.h"

@interface MapObservations ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSMutableDictionary<NSManagedObjectID *, MapObservation *> *observationIds;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MapAnnotationObservation *>  *annotationIds;
@property (nonatomic, strong) MapAnnotation *shapeAnnotation;
@property (nonatomic, strong) MapShapeObservation *shapeObservation;

@end

@implementation MapObservations

-(instancetype) initWithMapView: (MKMapView *) mapView {
    self = [super init];
    if (self) {
        _mapView = mapView;
        _observationIds = [[NSMutableDictionary alloc] init];
        _annotationIds = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void) addMapObservation: (MapObservation *) mapObservation {
    NSManagedObjectID *id = [mapObservation observation].objectID;
    [_observationIds setObject:mapObservation forKey:id];
    if ([MapObservations isAnnotation: mapObservation]){
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *) mapObservation;
        [_annotationIds setObject:mapAnnotationObservation forKey:[mapAnnotationObservation.annotation getIdAsNumber]];
    }
}

-(MapObservation *) observationOfId: (NSManagedObjectID *) observationId {
    return [_observationIds objectForKey:observationId];
}

-(Observation *) observationOfAnnotationId: (NSUInteger) annotationId {
    return [self observationOfAnnotationIdNumber:[NSNumber numberWithUnsignedInteger:annotationId]];
}

-(Observation *) observationOfAnnotationIdNumber: (NSNumber *) annotationId {
    Observation *observation = nil;
    MapAnnotationObservation *mapAnnotationObservation = [_annotationIds objectForKey:annotationId];
    if (mapAnnotationObservation != nil) {
        observation = [mapAnnotationObservation observation];
    } else if (_shapeAnnotation != nil && [annotationId intValue] == _shapeAnnotation.id ) {
        observation = [_shapeObservation observation];
    }
    return observation;
}

+(BOOL) isAnnotation: (MapObservation *) mapObservation {
    return [mapObservation class] == [MapAnnotationObservation class];
}

+(BOOL) isShape: (MapObservation *) mapObservation {
    return [mapObservation class] == [MapShapeObservation class];
}

- (void) removeObservationsNotInArray: (NSArray<NSManagedObjectID *> *) idArray {
    NSMutableArray<NSManagedObjectID *> *ids = [NSMutableArray arrayWithArray:[_observationIds allKeys]];
    [ids removeObjectsInArray:idArray];
    for (NSManagedObjectID *observationId in ids) {
        [self removeById:observationId];
    }
}

-(MapObservation *) removeById: (NSManagedObjectID *) observationId {
    MapObservation *mapObservation = [_observationIds objectForKey:observationId];
    if (mapObservation != nil) {
        [_observationIds removeObjectForKey:observationId];
        if ([MapObservations isAnnotation:mapObservation]){
            MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *) mapObservation;
            [_annotationIds removeObjectForKey:[[mapAnnotationObservation annotation] getIdAsNumber]];
        }
        [mapObservation removeFromMapView:_mapView];
    }
    
    return mapObservation;
}

-(void) hidden: (BOOL) hidden{
    for (MapObservation *mapObservation in _observationIds.allValues) {
        [mapObservation hidden:hidden fromMapView:_mapView];
    }
}

-(void) setShapeAnnotation: (MapAnnotation *) shapeAnnotation withShapeObservation: (MapShapeObservation *) shapeObservation {
    [self clearShapeAnnotation];
    _shapeAnnotation = shapeAnnotation;
    _shapeObservation = shapeObservation;
}

-(void) selectShapeAnnotation {
    if (_shapeAnnotation != nil) {
        [_mapView selectAnnotation:_shapeAnnotation animated:YES];
    }
}

-(void) clearShapeAnnotation {
    if (_shapeAnnotation != nil) {
        [_mapView removeAnnotation:_shapeAnnotation];
        _shapeAnnotation = nil;
    }
    _shapeObservation = nil;
}

-(void) clear{
    [self clearShapeAnnotation];
    for (MapObservation *shape in _observationIds.allValues) {
        [shape removeFromMapView:_mapView];
    }
    [_observationIds removeAllObjects];
    [_annotationIds removeAllObjects];
}

-(MapShapeObservation *) clickedShapeAtLocation: (CLLocationCoordinate2D) location{
    
    BOOL checkShapes = YES;
    CGPoint point = [self.mapView convertCoordinate:location toPointToView:self.mapView];
    for (MapAnnotationObservation *observationAnnotation in [self annotations]) {
        MKAnnotationView* view = [self.mapView viewForAnnotation:[observationAnnotation annotation]];
        if (CGRectContainsPoint(view.frame, point)) {
            checkShapes = NO;
            break;
        }
    }
    
    MapShapeObservation *mapShapeObservation = nil;
    if (checkShapes) {

        // Screen click map width tolerance
        float screenPercentage = [[NSUserDefaults standardUserDefaults] floatForKey:@"shape_screen_click_percentage"];
        double tolerance = self.mapView.visibleMapRect.size.width * screenPercentage;
        
        // Find the first polyline with the point on it, else find the first polygon
        for (MapShapeObservation *observationShape in [self shapes]) {
            enum GPKGMapShapeType shapeType = observationShape.shape.shapeType;
            if (mapShapeObservation == nil || shapeType == GPKG_MST_POLYLINE) {
                if([observationShape isOnShapeAtLocation:location withTolerance:tolerance andMapView:self.mapView]){
                    mapShapeObservation = observationShape;
                    if (shapeType == GPKG_MST_POLYLINE) {
                        break;
                    }
                }
            }
        }
    }
    
    return mapShapeObservation;
}

-(NSArray *) annotations {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [MapAnnotationObservation class]];
    return [self.observationIds.allValues filteredArrayUsingPredicate:predicate];
}

-(NSArray *) shapes {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [MapShapeObservation class]];
    return [self.observationIds.allValues filteredArrayUsingPredicate:predicate];
}

@end
