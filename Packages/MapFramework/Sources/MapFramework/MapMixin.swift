//
//  MapMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import CoreGraphics
import DataSourceTileOverlay
import SwiftUI

public protocol MapMixin {
    var uuid: UUID { get }
    func cleanupMixin()
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer?
    func traitCollectionUpdated(previous: UITraitCollection?)
    func regionDidChange(mapView: MKMapView, animated: Bool)
    func regionWillChange(mapView: MKMapView, animated: Bool)
    func didChangeUserTrackingMode(mapView: MKMapView, animated: Bool)
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView?
    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String: [String]]

    func setupMixin(mapView: MKMapView, mapState: MapState)
    func removeMixin(mapView: MKMapView, mapState: MapState)
    func updateMixin(mapView: MKMapView, mapState: MapState)
}

public extension MapMixin {
    var uuid: UUID {
        UUID()
    }

    func cleanupMixin() {
    }

    func polygonHitTest(polygonObservation: MKPolygon, location: CLLocationCoordinate2D) -> Bool {
        guard let renderer = (renderer(overlay: polygonObservation) as? MKPolygonRenderer ?? standardRenderer(overlay: polygonObservation) as? MKPolygonRenderer) else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)

        var onShape = renderer.path.contains(point)
        // If not on the polygon, check the complementary polygon path in case it crosses -180 / 180 longitude
        if !onShape {
            if let complementaryPath = complementaryWorldPath(feature: polygonObservation) {
//                let retained = complementaryPath.takeRetainedValue()
                onShape = complementaryPath.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
            }
        }

        return onShape
    }

    func lineHitTest(lineObservation: MKPolyline, location: CLLocationCoordinate2D, tolerance: Double) -> Bool {
        guard let renderer = (renderer(overlay: lineObservation) as? MKPolylineRenderer ?? standardRenderer(overlay: lineObservation) as? MKPolylineRenderer) else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)
        let strokedPath = renderer.path.copy(strokingWithWidth: tolerance, lineCap: .round, lineJoin: .round, miterLimit: 1)

        var onShape = strokedPath.contains(point)
        // If not on the line, check the complementary polygon path in case it crosses -180 / 180 longitude
        if !onShape {
            if let complementaryPath = complementaryWorldPath(feature: lineObservation) {
                let complimentaryStrokedPath = complementaryPath.copy(strokingWithWidth: tolerance, lineCap: .round, lineJoin: .round, miterLimit: 1)
                onShape = complimentaryStrokedPath.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
            }
        }

        return onShape
    }

    func complementaryWorldPath(feature: MKMultiPoint) -> CGPath? {
        self.complementaryWorldPath(points: feature.points(), pointCount: feature.pointCount)
    }

    func complementaryWorldPath(points: UnsafeMutablePointer<MKMapPoint>, pointCount: Int) -> CGPath? {
        var path: CGMutablePath?

        // Determine if the shape is drawn over the -180 / 180 longitude boundary and the direction
        var worldOverlap = 0
        for i in 0...pointCount {
            let mapPoint = points[i]
            if mapPoint.x < 0 {
                worldOverlap = -1
                break
            } else if mapPoint.x > MKMapSize.world.width {
                worldOverlap = 1
            }
        }

        // Shape crosses the -180 / 180 longitude boundary
        if worldOverlap != 0 {
            // Build the complementary points in the opposite world width direction
            var complementaryPoints: [MKMapPoint] = []
            for i in 0...pointCount {
                let mapPoint = points[i]
                var x = mapPoint.x
                if worldOverlap < 0 {
                    x += MKMapSize.world.width
                } else {
                    x -= MKMapSize.world.width
                }
                complementaryPoints.append(MKMapPoint(x: x, y: mapPoint.y))
            }

            // Build the path
            path = CGMutablePath()
            let firstPoint = complementaryPoints.removeFirst()
            path?.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
            for complementaryPoint in complementaryPoints {
                path?.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
            }
        }

        return path
    }

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        return nil
    }

    func standardRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let renderable = overlay as? OverlayRenderable {
            return renderable.renderer
        }
        // standard renderers
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let overlay = overlay as? MKTileOverlay {
            return HackTileOverlayRenderer(overlay: overlay)
        }
        return nil
    }

    func traitCollectionUpdated(previous: UITraitCollection?){ }
    func regionDidChange(mapView: MKMapView, animated: Bool) { }
    func regionWillChange(mapView: MKMapView, animated: Bool) { }
    func didChangeUserTrackingMode(mapView: MKMapView, animated: Bool) { }

    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        return nil
    }

    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String: [String]] {
        return [:]
    }
}
