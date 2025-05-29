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
