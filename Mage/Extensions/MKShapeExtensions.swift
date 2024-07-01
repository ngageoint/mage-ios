//
//  MKShapeExtensions.swift
//  Marlin
//
//  Created by Daniel Barela on 5/4/23.
//

import Foundation
import MapKit
import sf_wkt_ios
import MapFramework
import geopackage_ios

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
    
    func standardRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let renderable = overlay as? OverlayRenderable {
            return renderable.renderer
        }
        // standard renderers
        if let polygon = overlay as? MKPolygon, type(of: polygon) == MKPolygon.self {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let polyline = overlay as? MKPolyline, type(of: polyline) == MKPolyline.self {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let polyline = overlay as? MKPolyline, type(of: polyline) == MKGeodesicPolyline.self {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let circle = overlay as? MKCircle, type(of: circle) == MKCircle.self {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        }
        return nil
    }
}

extension MKPolygon {
    func hitTest(location: CLLocationCoordinate2D) -> Bool {
        guard let renderer = standardRenderer(overlay: self) as? MKPolygonRenderer else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)
        var onShape = renderer.path?.contains(point) ?? false
        // If not on the polygon, check the complementary polygon path in case it crosses -180 / 180 longitude
        if !onShape {
            if let complementaryPath: Unmanaged<CGPath> = GPKGMapUtils.complementaryWorldPath(of: self) {
                let retained = complementaryPath.takeRetainedValue()
                onShape = retained.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
            }
        }

        return onShape
    }
}

extension MKGeodesicPolyline {
    func hitTest(location: CLLocationCoordinate2D) -> Bool {
        guard let renderer = standardRenderer(overlay: self) as? MKPolylineRenderer else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)
        let onShape = renderer.path?.contains(point) ?? false
        return onShape
    }
}

extension MKPolyline {
    func hitTest(location: CLLocationCoordinate2D, distanceTolerance: Double) -> Bool {
        guard let renderer = standardRenderer(overlay: self) as? MKPolylineRenderer else {
            return false
        }
        renderer.invalidatePath()

        let mapPoint = MKMapPoint(location)
        let point = renderer.point(for: mapPoint)
        let bufferedPath = renderer.path.copy(
            strokingWithWidth: distanceTolerance * 2,
            lineCap: renderer.lineCap,
            lineJoin: renderer.lineJoin,
            miterLimit: renderer.miterLimit
        )
        let onShape = bufferedPath.contains(point)
        return onShape
    }
}

extension MKCircle {
    func circleHitTest(location: CLLocationCoordinate2D) -> Bool {
        guard let renderer = standardRenderer(overlay: self) as? MKCircleRenderer else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)
        return renderer.path?.contains(point) ?? false
    }
}
