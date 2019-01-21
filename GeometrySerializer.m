//
//  GeometrySerializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometrySerializer.h"
#import "SFLineString.h"
#import "SFPolygon.h"
#import "SFMultiPoint.h"
#import "SFMultiLineString.h"
#import "SFMultiPolygon.h"

@implementation GeometrySerializer

+(NSDictionary *) serializeGeometry: (SFGeometry *) geometry{
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    switch(geometry.geometryType){
        case SF_POINT:
            [json setObject:@"Point" forKey:@"type"];
            [json setObject:[self serializePoint:(SFPoint *)geometry] forKey:@"coordinates"];
            break;
        case SF_MULTIPOINT:
            [json setObject:@"MultiPoint" forKey:@"type"];
            [json setObject:[self serializeMultiPoint:(SFMultiPoint *)geometry] forKey:@"coordinates"];
            break;
        case SF_LINESTRING:
            [json setObject:@"LineString" forKey:@"type"];
            [json setObject:[self serializeLineString:(SFLineString *)geometry] forKey:@"coordinates"];
            break;
        case SF_MULTILINESTRING:
            [json setObject:@"MultiLineString" forKey:@"type"];
            [json setObject:[self serializeMultiLineString:(SFMultiLineString *)geometry] forKey:@"coordinates"];
            break;
        case SF_POLYGON:
            [json setObject:@"Polygon" forKey:@"type"];
            [json setObject:[self serializePolygon:(SFPolygon*)geometry] forKey:@"coordinates"];
            break;
        case SF_MULTIPOLYGON:
            [json setObject:@"MultiPolygon" forKey:@"type"];
            [json setObject:[self serializeMultiPolygon:(SFMultiPolygon *)geometry] forKey:@"coordinates"];
            break;
        case SF_GEOMETRYCOLLECTION:
            [json setObject:@"GeometryCollection" forKey:@"type"];
            [json setObject:[self serializeGeometryCollection:(SFGeometryCollection *)geometry] forKey:@"geometries"];
            break;
        default:
            [NSException raise:@"Unsupported Geometry" format:@"Unsupported geometry type: %u", geometry.geometryType];
    }
    
    return json;
}

+(NSArray *) serializeLineString: (SFLineString *) lineString{
    return [self serializePoints:lineString.points andClose:NO];
}

+(NSArray *) serializeLineString: (SFLineString *) lineString andClose: (BOOL) close{
    return [self serializePoints:lineString.points andClose:close];
}

+(NSArray *) serializePolygon: (SFPolygon *) polygon{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    [coordinates addObject:[self serializeLineString:[polygon.lineStrings objectAtIndex:0] andClose:true]];
    for(int i = 1; i < [polygon numRings]; i++){
        [coordinates addObject:[self serializeLineString:[polygon.lineStrings objectAtIndex:i] andClose:true]];
    }
    return coordinates;
}

+(NSArray *) serializePoints: (NSArray *) points andClose: (BOOL) close{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(SFPoint *point in points){
        [coordinates addObject:[self serializePoint:point]];
    }
    if(close){
        SFPoint *firstPoint = [points objectAtIndex:0];
        SFPoint *lastPoint = [points objectAtIndex:points.count - 1];
        if(![firstPoint.x isEqualToNumber:lastPoint.x] || ![firstPoint.y isEqualToNumber:lastPoint.y]){
            [coordinates addObject:[self serializePoint:firstPoint]];
        }
    }
    return coordinates;
}

+(NSArray *) serializePoint: (SFPoint *) point{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    [coordinates addObject:point.x];
    [coordinates addObject:point.y];
    if(point.hasZ){
        [coordinates addObject:point.z];
    }
    return coordinates;
}

+(NSArray *) serializeMultiPoint: (SFMultiPoint *) multiPoint{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(SFPoint *point in [multiPoint points]){
        [coordinates addObject:[self serializePoint:point]];
    }
    return coordinates;
}

+(NSArray *) serializeMultiLineString: (SFMultiLineString *) multiLineString{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(SFLineString *lineString in [multiLineString lineStrings]){
        [coordinates addObject:[self serializeLineString:lineString]];
    }
    return coordinates;
}

+(NSArray *) serializeMultiPolygon: (SFMultiPolygon *) multiPolygon{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for(SFPolygon *polygon in [multiPolygon polygons]){
        [coordinates addObject:[self serializePolygon:polygon]];
    }
    return coordinates;
}

+(NSArray *) serializeGeometryCollection: (SFGeometryCollection *) geometryCollection{
    NSMutableArray *geometries = [[NSMutableArray alloc] init];
    for(SFGeometry *geometry in geometryCollection.geometries){
        [geometries addObject:[self serializeGeometry:geometry]];
    }
    return geometries;
}

@end
