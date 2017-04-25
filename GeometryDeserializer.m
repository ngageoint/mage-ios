//
//  GeometryDeserializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/24/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometryDeserializer.h"
#import "WKBPoint.h"
#import "WKBMultiPoint.h"
#import "WKBLineString.h"
#import "WKBMultiLineString.h"
#import "WKBPolygon.h"
#import "WKBMultiPolygon.h"
#import "WKBGeometryCollection.h"

@implementation GeometryDeserializer

+(WKBGeometry *) parseGeometry: (NSDictionary *) json{
    
    NSString *typeName = [json objectForKey:@"type"];
    NSArray *coordinates = [json objectForKey:@"coordinates"];
    
    if(typeName == nil){
        [NSException raise:@"Geometry Type" format:@"'type' not present"];
    }
    
    WKBGeometry *geometry = nil;
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

+(WKBPoint *) toPoint: (NSArray *) coordinates{
    double x = [[coordinates objectAtIndex:0] doubleValue];
    double y = [[coordinates objectAtIndex:1] doubleValue];
    WKBPoint *point = [[WKBPoint alloc] initWithXValue:x andYValue:y];
    return point;
}

+(WKBMultiPoint *) toMultiPoint: (NSArray *) coordinates{
    
    WKBMultiPoint *multiPoint = [[WKBMultiPoint alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        WKBPoint *point = [self toPoint: [coordinates objectAtIndex:i]];
        [multiPoint addPoint:point];
    }
    
    return multiPoint;
}

+(WKBLineString *) toLineString: (NSArray *) coordinates{

    WKBLineString *lineString = [[WKBLineString alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        WKBPoint *point = [self toPoint: [coordinates objectAtIndex:i]];
        [lineString addPoint:point];
    }
    
    return lineString;
}

+(WKBMultiLineString *) toMultiLineString: (NSArray *) coordinates{

    WKBMultiLineString *multiLineString = [[WKBMultiLineString alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        WKBLineString *lineString = [self toLineString: [coordinates objectAtIndex:i]];
        [multiLineString addLineString:lineString];
    }
    
    return multiLineString;
}

+(WKBPolygon *) toPolygon: (NSArray *) coordinates{

    WKBPolygon *polygon = [[WKBPolygon alloc] init];
    
    WKBLineString *polygonLineString = [self toLineString:[coordinates objectAtIndex:0]];
    [polygon addRing:polygonLineString];
    
    for (int i = 1; i < coordinates.count; ++i) {
        WKBLineString *holeLineString = [self toLineString: [coordinates objectAtIndex:i]];
        [polygon addRing:holeLineString];
    }
    
    return polygon;
}

+(WKBMultiPolygon *) toMultiPolygon: (NSArray *) coordinates{

    WKBMultiPolygon *multiPolygon = [[WKBMultiPolygon alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        WKBPolygon *polygon = [self toPolygon: [coordinates objectAtIndex:i]];
        [multiPolygon addPolygon:polygon];
    }
    
    return multiPolygon;
}

+(WKBGeometryCollection *) toGeometryCollection: (NSArray *) coordinates{

    WKBGeometryCollection *geometryCollection = [[WKBGeometryCollection alloc] init];
    
    for (int i = 0; i < coordinates.count; ++i) {
        WKBGeometry *geometry = [self parseGeometry: [coordinates objectAtIndex:i]];
        [geometryCollection addGeometry:geometry];
    }
    
    return geometryCollection;
}

@end
