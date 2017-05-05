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

-(instancetype) initWithMapView: (MKMapView *) mapView{
    self = [super init];
    if(self){
        _mapView = mapView;
        _observationIds = [[NSMutableDictionary alloc] init];
        _annotationIds = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void) addMapObservation: (MapObservation *) mapObservation{
    NSManagedObjectID *id = [mapObservation observation].objectID;
    [_observationIds setObject:mapObservation forKey:id];
    if([MapObservations isAnnotation: mapObservation]){
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *) mapObservation;
        [_annotationIds setObject:mapAnnotationObservation forKey:[mapAnnotationObservation.annotation getIdAsNumber]];
    }
}

-(MapObservation *) observationOfId: (NSManagedObjectID *) observationId{
    return [_observationIds objectForKey:observationId];
}

-(Observation *) observationOfAnnotationId: (NSUInteger) annotationId{
    return [self observationOfAnnotationIdNumber:[NSNumber numberWithUnsignedInteger:annotationId]];
}

-(Observation *) observationOfAnnotationIdNumber: (NSNumber *) annotationId{
    Observation *observation = nil;
    MapAnnotationObservation *mapAnnotationObservation = [_annotationIds objectForKey:annotationId];
    if (mapAnnotationObservation != nil) {
        observation = [mapAnnotationObservation observation];
    } else if (_shapeAnnotation != nil && [annotationId intValue] == _shapeAnnotation.id ) {
        observation = [_shapeObservation observation];
    }
    return observation;
}

+(BOOL) isAnnotation: (MapObservation *) mapObservation{
    return [mapObservation class] == [MapAnnotationObservation class];
}

+(BOOL) isShape: (MapObservation *) mapObservation{
    return [mapObservation class] == [MapShapeObservation class];
}

-(MapObservation *) removeById: (NSManagedObjectID *) observationId{
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

-(void) setShapeAnnotation: (MapAnnotation *) shapeAnnotation withShapeObservation: (MapShapeObservation *) shapeObservation{
    [self clearShapeAnnotation];
    _shapeAnnotation = shapeAnnotation;
    _shapeObservation = shapeObservation;
}

-(void) clearShapeAnnotation{
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

-(MapShapeObservation *) clickedShapeWithLocation: (CLLocation *) location{
    
    // how many meters away from the click can the geometry be?
    double tolerance = [MapUtils lineToleranceWithMapView:self.mapView];
    
    // Find the first polyline with the point on it, else find the first polygon
    MapShapeObservation *mapShapeObservation = nil;
    for (MapShapeObservation *observationShape in [self shapes]) {
        enum GPKGMapShapeType shapeType = observationShape.shape.shapeType;
        if (mapShapeObservation == nil || shapeType == GPKG_MST_POLYLINE) {
            if([observationShape isOnShapeWithLocation:location andTolerance:tolerance]){
                mapShapeObservation = observationShape;
                if (shapeType == GPKG_MST_POLYLINE) {
                    break;
                }
            }
        }
    }
    
    return mapShapeObservation;
}

-(MapAnnotationObservationEnumerator *) annotations{
    return [[MapAnnotationObservationEnumerator alloc] initWithObservations:_observationIds.allValues];
}


-(MapShapeObservationEnumerator *) shapes{
    return [[MapShapeObservationEnumerator alloc] initWithObservations:_observationIds.allValues];
}

@end

@implementation MapAnnotationObservationEnumerator

-(instancetype) initWithObservations: (NSArray<MapObservation *> *) observations{
    self = [super initWithType:[MapAnnotation class] andObservations:observations];
    return self;
}

@end

@implementation MapShapeObservationEnumerator

-(instancetype) initWithObservations: (NSArray<MapObservation *> *) observations{
    self = [super initWithType:[MapObservation class] andObservations:observations];
    return self;
}

@end

@interface MapObservationsEnumerator ()

@property (nonatomic, strong) Class type;
@property (nonatomic, strong) NSEnumerator<MapObservation *> *observations;
@property (nonatomic, strong) MapObservation *observation;

@end

@implementation MapObservationsEnumerator

-(instancetype) initWithType: (Class) type andObservations: (NSArray<MapObservation *> *) observations{
    self = [super init];
    if(self != nil){
        _type = type;
        _observations = [observations objectEnumerator];
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len {
    
    // First call
    if(state->state == 0)
    {
        state->mutationsPtr = &state->extra[0];
        state->state = 1;
    }
    
    // Verify there are more observations to return
    _observation = [_observations nextObject];
    while(_observation != nil){
        // Check if the desired type
        if([_observation class] == _type){
            break;
        }
        _observation = [_observations nextObject];
    }
    
    // No more observations
    if(_observation == nil){
        return 0;
    }
    
    // Set the observation
    __unsafe_unretained MapObservation *tempObservation = _observation;
    state->itemsPtr = &tempObservation;
    
    return 1;
}

@end
