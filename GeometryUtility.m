//
//  GeometryUtility.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GeometryUtility.h"
#import "WKBByteReader.h"
#import "WKBGeometryReader.h"
#import "WKBByteWriter.h"
#import "WKBGeometryWriter.h"

@implementation GeometryUtility

+(WKBGeometry *) toGeometryFromGeometryData: (NSData *) geometryData{
    WKBByteReader *reader = [[WKBByteReader alloc] initWithData: geometryData];
    reader.byteOrder = CFByteOrderBigEndian;
    WKBGeometry *geometry = [WKBGeometryReader readGeometryWithReader: reader];
    return geometry;
}

+(NSData *) toGeometryDataFromGeometry: (WKBGeometry *) geometry{
    NSData *data = nil;
    WKBByteWriter *writer = [[WKBByteWriter alloc] init];
    @try {
        writer.byteOrder = CFByteOrderBigEndian;
        [WKBGeometryWriter writeGeometry:geometry withWriter:writer];
        data = [writer getData];
    } @catch (NSException *exception) {
        NSLog(@"Problem reading observation, %@: %@", [exception name], [exception reason]);
    } @finally {
        [writer close];
    }
    return data;
}

@end
