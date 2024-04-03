//
//  MapMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import geopackage_ios
import CoreGraphics
import DataSourceTileOverlay

struct AnnotationsAndOverlays {
    let annotations: [MKAnnotation]
    let overlays: [MKOverlay]
}

protocol MapMixin {
    func cleanupMixin()
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer?
    func traitCollectionUpdated(previous: UITraitCollection?)
    func regionDidChange(mapView: MKMapView, animated: Bool)
    func regionWillChange(mapView: MKMapView, animated: Bool)
    func didChangeUserTrackingMode(mapView: MKMapView, animated: Bool)
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView?
    func items(at location: CLLocationCoordinate2D) -> [Any]?
    func applyTheme(scheme: MDCContainerScheming?)
    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]?

    func setupMixin(mapView: MKMapView, mapState: MapState)
    func removeMixin(mapView: MKMapView, mapState: MapState)
    func updateMixin(mapView: MKMapView, mapState: MapState)
}


class MapState: ObservableObject, Hashable {
    static func == (lhs: MapState, rhs: MapState) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id = UUID()

    @Published var userTrackingMode: Int = Int(MKUserTrackingMode.none.rawValue)
    @Published var mixinStates: [String: Any] = [:]
}

extension MapMixin {

    func cleanupMixin() {
    }

    func polygonHitTest(polygonObservation: StyledPolygon, location: CLLocationCoordinate2D) -> Bool {
        guard let renderer = (renderer(overlay: polygonObservation) as? MKPolygonRenderer ?? standardRenderer(overlay: polygonObservation) as? MKPolygonRenderer) else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)

        var onShape = renderer.path.contains(point)
        // If not on the polygon, check the complementary polygon path in case it crosses -180 / 180 longitude
        if !onShape {
            if let complementaryPath: Unmanaged<CGPath> = GPKGMapUtils.complementaryWorldPath(of: polygonObservation) {
                let retained = complementaryPath.takeRetainedValue()
                onShape = retained.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
            }
        }

        return onShape
    }

    func lineHitTest(lineObservation: StyledPolyline, location: CLLocationCoordinate2D, tolerance: Double) -> Bool {
        guard let renderer = (renderer(overlay: lineObservation) as? MKPolylineRenderer ?? standardRenderer(overlay: lineObservation) as? MKPolylineRenderer) else {
            return false
        }
        let mapPoint = MKMapPoint.init(location)
        let point = renderer.point(for: mapPoint)
        let strokedPath = renderer.path.copy(strokingWithWidth: tolerance, lineCap: .round, lineJoin: .round, miterLimit: 1)

        var onShape = strokedPath.contains(point)
        // If not on the line, check the complementary polygon path in case it crosses -180 / 180 longitude
        if !onShape {
            if let complementaryPath: Unmanaged<CGPath> = GPKGMapUtils.complementaryWorldPath(of: lineObservation) {
                let retained = complementaryPath.takeRetainedValue()
                let complimentaryStrokedPath = retained.copy(strokingWithWidth: tolerance, lineCap: .round, lineJoin: .round, miterLimit: 1)
                onShape = complimentaryStrokedPath.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
            }
        }

        return onShape
    }

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        return standardRenderer(overlay: overlay)
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

    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        return nil
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return nil
    }

    func applyTheme(scheme: MDCContainerScheming?) {
    }
}
