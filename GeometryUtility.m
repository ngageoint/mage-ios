//
//  GeometryUtility.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometryUtility.h"
#import "SFByteReader.h"
#import "SFWGeometryReader.h"
#import "SFByteWriter.h"
#import "SFWGeometryWriter.h"
#import "SFGeometryUtils.h"
#import "SFPProjectionConstants.h"

@implementation GeometryUtility

+(SFGeometry *) toGeometryFromGeometryData: (NSData *) geometryData{
    SFByteReader *reader = [[SFByteReader alloc] initWithData: geometryData];
    reader.byteOrder = CFByteOrderBigEndian;
    SFGeometry *geometry = [SFWGeometryReader readGeometryWithReader: reader];
    return geometry;
}

+(NSData *) toGeometryDataFromGeometry: (SFGeometry *) geometry{
    NSData *data = nil;
    SFByteWriter *writer = [[SFByteWriter alloc] init];
    @try {
        writer.byteOrder = CFByteOrderBigEndian;
        [SFWGeometryWriter writeGeometry:geometry withWriter:writer];
        data = [writer getData];
    } @catch (NSException *exception) {
        NSLog(@"Problem reading observation, %@: %@", [exception name], [exception reason]);
    } @finally {
        [writer close];
    }
    return data;
}

+(SFPoint *) centroidOfGeometry: (SFGeometry *) geometry{
    SFPoint *centroid = nil;
    if(geometry.geometryType == SF_POINT){
        centroid = (SFPoint *) geometry;
    }else{
        SFGeometry *clonedGeometry = [geometry mutableCopy];
        [SFGeometryUtils minimizeGeometry:clonedGeometry withMaxX:PROJ_WGS84_HALF_WORLD_LON_WIDTH];
        centroid = [SFGeometryUtils centroidOfGeometry:clonedGeometry];
        [SFGeometryUtils normalizeGeometry:centroid withMaxX:PROJ_WGS84_HALF_WORLD_LON_WIDTH];
    }
    return centroid;
}

@end
