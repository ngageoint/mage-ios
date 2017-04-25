//
//  GeometrySerializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometrySerializer.h"
#import "WKBLineString.h"
#import "WKBPolygon.h"
#import "WKBMultiPoint.h"
#import "WKBMultiLineString.h"
#import "WKBMultiPolygon.h"

@implementation GeometrySerializer

+(NSDictionary *) serializeGeometry: (WKBGeometry *) geometry{
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    switch(geometry.geometryType){
        case WKB_POINT:
            [json setObject:@"Point" forKey:@"type"];
            
            break;
        case WKB_MULTIPOINT:
            [json setObject:@"MultiPoint" forKey:@"type"];
            
            break;
        case WKB_LINESTRING:
            [json setObject:@"LineString" forKey:@"type"];
            
            break;
        case WKB_MULTILINESTRING:
            [json setObject:@"MultiLineString" forKey:@"type"];
            
            break;
        case WKB_POLYGON:
            [json setObject:@"Polygon" forKey:@"type"];
            
            break;
        case WKB_MULTIPOLYGON:
            [json setObject:@"MultiPolygon" forKey:@"type"];
            
            break;
        case WKB_GEOMETRYCOLLECTION:
            [json setObject:@"GeometryCollection" forKey:@"type"];
            
            break;
        default:
            [NSException raise:@"Unsupported Geometry" format:@"Unsupported geometry type: %u", geometry.geometryType];
    }
    
    return json;
}

+(NSArray *) serializeLineString: (WKBLineString *) lineString{
    return [self serializePoints:lineString.points andClose:NO];
}

+(NSArray *) serializeLineString: (WKBLineString *) lineString andClose: (BOOL) close{
    return [self serializePoints:lineString.points andClose:close];
}

+(NSArray *) serializePolygon: (WKBPolygon *) polygon{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    [coordinates addObject:[self serializeLineString:[polygon.rings objectAtIndex:0] andClose:true]];
    for(int i = 1; i < (int)[polygon numRings]; i++){
        [coordinates addObject:[self serializeLineString:[polygon.rings objectAtIndex:i] andClose:true]];
    }
    return coordinates;
}

+(NSArray *) serializePoints: (NSArray *) points andClose: (BOOL) close{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(WKBPoint *point in points){
        [coordinates addObject:[self serializePoint:point]];
    }
    if(close){
        WKBPoint *firstPoint = [points objectAtIndex:0];
        WKBPoint *lastPoint = [points objectAtIndex:points.count - 1];
        if(![firstPoint.x isEqualToNumber:lastPoint.x] || ![firstPoint.y isEqualToNumber:lastPoint.y]){
            [coordinates addObject:[self serializePoint:firstPoint]];
        }
    }
    return coordinates;
}

+(NSArray *) serializePoint: (WKBPoint *) point{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    [coordinates addObject:point.x];
    [coordinates addObject:point.y];
    if(point.hasZ){
        [coordinates addObject:point.z];
    }
    return coordinates;
}

+(NSArray *) serializeMultiPoint: (WKBMultiPoint *) multiPoint{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(WKBPoint *point in [multiPoint getPoints]){
        [coordinates addObject:[self serializePoint:point]];
    }
    return coordinates;
}

+(NSArray *) serializeMultiLineString: (WKBMultiLineString *) multiLineString{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(WKBLineString *lineString in [multiLineString getLineStrings]){
        [coordinates addObject:[self serializeLineString:lineString]];
    }
    return coordinates;
}

+(NSArray *) serializeMultiPolygon: (WKBMultiPolygon *) multiPolygon{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(WKBPolygon *polygon in [multiPolygon getPolygons]){
        [coordinates addObject:[self serializePolygon:polygon]];
    }
    return coordinates;
}

+(NSArray *) serializeGeometryCollection: (WKBGeometryCollection *) geometryCollection{
    NSMutableArray *geometries = [[NSMutableArray alloc] init];
    for(WKBGeometry *geometry in geometryCollection.geometries){
        [geometries addObject:[self serializeGeometry:geometry]];
    }
    return geometries;
}

@end
