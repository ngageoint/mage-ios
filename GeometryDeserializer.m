//
//  GeometryDeserializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/24/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometryDeserializer.h"
#import "SFPoint.h"
#import "SFMultiPoint.h"
#import "SFLineString.h"
#import "SFMultiLineString.h"
#import "SFPolygon.h"
#import "SFMultiPolygon.h"
#import "SFGeometryCollection.h"

@implementation GeometryDeserializer

+(SFGeometry *) parseGeometry: (NSDictionary *) json{
    
    NSString *typeName = [json objectForKey:@"type"];
    NSArray *coordinates = [json objectForKey:@"coordinates"];
    
    if(typeName == nil){
        [NSException raise:@"Geometry Type" format:@"'type' not present"];
    }
    
    SFGeometry *geometry = nil;
    if([typeName isEqualToString:@"Point"]){
        geometry = [self toPoint:coordinates];
    } else if([typeName isEqualToString:@"MultiPoint"]){
        geometry = [self toMultiPoint:coordinates];
    } else if([typeName isEqualToString:@"LineString"]){
        geometry = [self toLineString:coordinates];
    } else if([typeName isEqualToString:@"MultiLineString"]){
        geometry = [self toMultiLineString:coordinates];
    } else if([typeName isEqualToString:@"Polygon"]){
        geometry = [self toPolygon:coordinates];
    } else if([typeName isEqualToString:@"MultiPolygon"]){
        geometry = [self toMultiPolygon:coordinates];
    } else if([typeName isEqualToString:@"GeometryCollection"]){
        geometry = [self toGeometryCollection:coordinates];
    }else{
        [NSException raise:@"Geometry Type" format:@"'type' not supported: %@", typeName];
    }
    
    return geometry;
}

+(SFPoint *) toPoint: (NSArray *) coordinates{
    double x = [[coordinates objectAtIndex:0] doubleValue];
    double y = [[coordinates objectAtIndex:1] doubleValue];
    SFPoint *point = [[SFPoint alloc] initWithXValue:x andYValue:y];
    return point;
}

+(SFMultiPoint *) toMultiPoint: (NSArray *) coordinates{
    
    SFMultiPoint *multiPoint = [[SFMultiPoint alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        SFPoint *point = [self toPoint: [coordinates objectAtIndex:i]];
        [multiPoint addPoint:point];
    }
    
    return multiPoint;
}

+(SFLineString *) toLineString: (NSArray *) coordinates{

    SFLineString *lineString = [[SFLineString alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        SFPoint *point = [self toPoint: [coordinates objectAtIndex:i]];
        [lineString addPoint:point];
    }
    
    return lineString;
}

+(SFMultiLineString *) toMultiLineString: (NSArray *) coordinates{

    SFMultiLineString *multiLineString = [[SFMultiLineString alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        SFLineString *lineString = [self toLineString: [coordinates objectAtIndex:i]];
        [multiLineString addLineString:lineString];
    }
    
    return multiLineString;
}

+(SFPolygon *) toPolygon: (NSArray *) coordinates{

    SFPolygon *polygon = [[SFPolygon alloc] init];
    
    SFLineString *polygonLineString = [self toLineString:[coordinates objectAtIndex:0]];
    [polygon addRing:polygonLineString];
    
    for (int i = 1; i < coordinates.count; ++i) {
        SFLineString *holeLineString = [self toLineString: [coordinates objectAtIndex:i]];
        [polygon addRing:holeLineString];
    }
    
    return polygon;
}

+(SFMultiPolygon *) toMultiPolygon: (NSArray *) coordinates{

    SFMultiPolygon *multiPolygon = [[SFMultiPolygon alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        SFPolygon *polygon = [self toPolygon: [coordinates objectAtIndex:i]];
        [multiPolygon addPolygon:polygon];
    }
    
    return multiPolygon;
}

+(SFGeometryCollection *) toGeometryCollection: (NSArray *) coordinates{

    SFGeometryCollection *geometryCollection = [[SFGeometryCollection alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        SFGeometry *geometry = [self parseGeometry: [coordinates objectAtIndex:i]];
        [geometryCollection addGeometry:geometry];
    }
    
    return geometryCollection;
}

@end
