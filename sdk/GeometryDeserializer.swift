//
//  GeometryDeserializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/24/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

import sf_ios

@objc public class GeometryDeserializer: NSObject {
    
    @objc public static func parseGeometry(json: [AnyHashable: Any]?) -> SFGeometry? {
        guard let json = json, let typeName = json["type"] as? String, let coordinates = json["coordinates"] else {
            return nil;
        }
        switch typeName {
        case "Point":
            if let coordinates = coordinates as? [NSNumber] {
                return GeometryDeserializer.toPoint(coordinates: coordinates);
            }
        case "MultiPoint":
            if let coordinates = coordinates as? [[NSNumber]] {
                return GeometryDeserializer.toMultiPoint(coordinates: coordinates);
            }
        case "LineString":
            if let coordinates = coordinates as? [[NSNumber]] {
                return GeometryDeserializer.toLineString(coordinates: coordinates);
            }
        case "MultiLineString":
            if let coordinates = coordinates as? [[[NSNumber]]] {
                return GeometryDeserializer.toMultiLineString(coordinates: coordinates);
            }
        case "Polygon":
            if let coordinates = coordinates as? [[[NSNumber]]] {
                return GeometryDeserializer.toPolygon(coordinates: coordinates);
            }
        case "MultiPolygon":
            if let coordinates = coordinates as? [[[[NSNumber]]]] {
                return GeometryDeserializer.toMultiPolygon(coordinates: coordinates);
            }
        case "GeometryCollection":
            if let geometries = coordinates as? [[AnyHashable : Any]] {
                return GeometryDeserializer.toGeometryCollection(coordinates: geometries);
            }
        default:
            return nil;
        }
        return nil;
    }
    
    static func toPoint(coordinates: [NSNumber]) -> SFPoint {
        let point: SFPoint = SFPoint(xValue: coordinates[0].doubleValue, andYValue: coordinates[1].doubleValue)
        return point;
    }
    
    static func toMultiPoint(coordinates: [[NSNumber]]) -> SFMultiPoint {
        let multiPoint: SFMultiPoint = SFMultiPoint();
        for coordinate in coordinates {
            multiPoint.addPoint(GeometryDeserializer.toPoint(coordinates: coordinate))
        }
        return multiPoint;
    }
    
    static func toLineString(coordinates: [[NSNumber]]) -> SFLineString {
        let lineString: SFLineString = SFLineString();
        for coordinate in coordinates {
            lineString.addPoint(GeometryDeserializer.toPoint(coordinates: coordinate))
        }
        return lineString;
    }

    static func toMultiLineString(coordinates: [[[NSNumber]]]) -> SFMultiLineString {
        let multiLineString: SFMultiLineString = SFMultiLineString();
        for coordinate in coordinates {
            multiLineString.addLineString(GeometryDeserializer.toLineString(coordinates: coordinate))
        }
        return multiLineString
    }

    static func toPolygon(coordinates:[[[NSNumber]]]) -> SFPolygon {
        let polygon: SFPolygon = SFPolygon();
        if let first = coordinates.first {
            polygon.addRing(GeometryDeserializer.toLineString(coordinates: first))
        }
        for coordinate in coordinates.dropFirst() {
            polygon.addRing(GeometryDeserializer.toLineString(coordinates: coordinate))
        }
        return polygon
    }
    
    static func toMultiPolygon(coordinates:[[[[NSNumber]]]]) -> SFMultiPolygon {
        let multiPolygon: SFMultiPolygon = SFMultiPolygon();
        for coordinate in coordinates {
            multiPolygon.addPolygon(GeometryDeserializer.toPolygon(coordinates: coordinate))
        }
        return multiPolygon;
    }

    static func toGeometryCollection(coordinates: [[AnyHashable : Any]]) -> SFGeometryCollection {
        let geometryCollection: SFGeometryCollection = SFGeometryCollection();
        for coordinate in coordinates {
            geometryCollection.addGeometry(GeometryDeserializer.parseGeometry(json: coordinate))
        }
        return geometryCollection;
    }
}
