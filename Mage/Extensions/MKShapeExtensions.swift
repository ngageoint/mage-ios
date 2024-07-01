//
//  MKShapeExtensions.swift
//  Marlin
//
//  Created by Daniel Barela on 5/4/23.
//

import Foundation
import MapKit
import sf_wkt_ios

extension MKShape {
    static func fromWKT(wkt: String, distance: Double?) -> MKShape? {
        let geometry = SFWTGeometryReader.readGeometry(withText: wkt)
        
        return MKShape.fromGeometry(geometry: geometry, distance: distance)
    }
    
    static func fromGeometry(geometry: SFGeometry?, distance: Double?) -> MKShape? {
        var mapPoints: [MKMapPoint] = []
        switch geometry {
        case let point as SFPoint:
            let coordinate = CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
            if let distance = distance {
                // this is really a circle
                return MKCircle(center: coordinate, radius: distance)
            }
            let point = MKPointAnnotation()
            point.coordinate = coordinate
            return point
        case let polygon as SFPolygon:
            if let lineString = polygon.ring(at: 0), let points = lineString.points {
                for case let point as SFPoint in points {
                    mapPoints.append(
                        MKMapPoint(
                            CLLocationCoordinate2D(
                                latitude: point.y.doubleValue,
                                longitude: point.x.doubleValue
                            )
                        )
                    )
                }
            }
            return MKPolygon(points: &mapPoints, count: mapPoints.count)
        case let line as SFLineString:
            if let points = line.points {
                for case let point as SFPoint in points {
                    mapPoints.append(
                        MKMapPoint(
                            CLLocationCoordinate2D(
                                latitude: point.y.doubleValue,
                                longitude: point.x.doubleValue
                            )
                        )
                    )
                }
            }
            return MKGeodesicPolyline(points: &mapPoints, count: mapPoints.count)
        default:
            return nil
        }
    }
}
