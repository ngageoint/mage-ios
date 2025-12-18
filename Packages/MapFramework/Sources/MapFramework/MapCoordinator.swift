//
//  MapCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import Combine

public class MapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
    var mapView: MKMapView?
    var mapScale: MKScaleView?
    var map: MapProtocol
    var focusedAnnotation: DataSourceAnnotation?
    var focusMapOnItemSink: AnyCancellable?

    var setCenter: CLLocationCoordinate2D?
    var trackingModeSet: MKUserTrackingMode?

    var forceCenterDate: Date?
    var centerDate: Date?

    var currentRegion: MKCoordinateRegion?

    var mixins: [any MapMixin] = []

    var allowMapTapsOnItems: Bool = true

    init(_ map: MapProtocol, focusNotification: NSNotification.Name) {
        self.map = map
        super.init()

        //        focusMapOnItemSink =
        //        NotificationCenter.default.publisher(for: focusNotification)
        //            .compactMap {$0.object as? FocusMapOnItemNotification}
        //            .sink(receiveValue: { [weak self] in
        //                NSLog("Focus notification recieved")
        //                self?.focusItem(notification: $0)
        //            })
    }

    func handleTappedItems(
        itemKeys: [String: [String]],
        mapName: String
    ) {
        Task {
            await MainActor.run {
                let notification = MapItemsTappedNotification(
                                        itemKeys: itemKeys
                    //                    mapName: mapName
                )
                NotificationCenter.default.post(name: map.notificationOnTap, object: notification)
            }
        }
    }

    @objc func singleTapGesture(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let mapGesture = tapGestureRecognizer as? MapSingleTap, let mapView = mapGesture.mapView else {
            return
        }
        if tapGestureRecognizer.state == .ended {
            self.mapTap(
                tapPoint: tapGestureRecognizer.location(in: mapView),
                gesture: tapGestureRecognizer,
                mapView: mapView)
        }
    }

    @objc func longPressGesture(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let mapGesture = longPressGestureRecognizer as? MapLongPress, let mapView = mapGesture.mapView else {
            return
        }

        if mapGesture.state == .began {
            let coordinate = mapView.convert(mapGesture.location(in: mapView), toCoordinateFrom: mapView)
            NotificationCenter.default.post(name: map.notificationOnLongPress, object: coordinate)
        }
    }

    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {

            guard let annotation = view.annotation as? DataSourceAnnotation else {
                continue
            }
            if annotation.shouldEnlarge {
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                    annotation.enlargeAnnoation()
                }
            }

            if annotation.shouldShrink {
                // have to enlarge it without animmation because it is added to the map at the original size
                annotation.enlargeAnnoation()
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                    annotation.shrinkAnnotation()
                    mapView.removeAnnotation(annotation)
                }
            }
        }

    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let renderableOverlay = overlay as? OverlayRenderable {
            return renderableOverlay.renderer
        }
        for mixin in map.mixins.mixins {
            if let renderer = mixin.renderer(overlay: overlay) {
                return renderer
            }
        }
        return MKTileOverlayRenderer(overlay: overlay)
    }

    // TODO: always returns nil, only being called when you open an observation or user from People tab
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        for mixin in map.mixins.mixins {
            if let view = mixin.viewForAnnotation(annotation: annotation, mapView: mapView) {
                return view
            }
        }
        return nil
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {}

    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {}

    public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        DispatchQueue.main.async { [self] in
            map.mapState.userTrackingMode = mode.rawValue
        }
    }

    func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for mixin in map.mixins.mixins {
            mixin.traitCollectionUpdated(previous: previousTraitCollection)
        }
    }
}

extension MapCoordinator {
    func setMapRegion(region: MKCoordinateRegion) {
        currentRegion = region
        self.mapView?.setRegion(region, animated: true)
    }

    func setCoordinateCenter(coordinate: CLLocationCoordinate2D) {
        setCenter = coordinate
        self.mapView?.setCenter(coordinate, animated: true)
    }

    func addAnnotation(annotation: MKAnnotation) {
        mapView?.addAnnotation(annotation)
    }

    func focusItem(notification: FocusMapOnItemNotification) {}

    func mapTap(tapPoint: CGPoint, gesture: UITapGestureRecognizer, mapView: MKMapView?) {
        guard let mapView = mapView, allowMapTapsOnItems else {
            return
        }

        mapView.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mapView.isZoomEnabled = true
        }

        let tapCoord = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        var annotationsTapped: [MKAnnotation] = []
        let visibleMapRect = mapView.visibleMapRect
        let annotationsVisible = mapView.annotations(in: visibleMapRect)

        for annotation in annotationsVisible {
            if let mkAnnotation = annotation as? MKAnnotation, let view = mapView.view(for: mkAnnotation) {
                let location = gesture.location(in: view)
                if view.bounds.contains(location) {
                    annotationsTapped.append(mkAnnotation)
                }
            }
        }
        Task { [annotationsTapped] in

            var items: [Any] = []
            var itemKeys: [String: [String]] = [:]
            for mixin in map.mixins.mixins.reversed() {
                let matchedItemKeys = await mixin.itemKeys(at: tapCoord, mapView: mapView, touchPoint: tapPoint)
                itemKeys.merge(matchedItemKeys) { current, new in
                    current + new
                }
            }
            handleTappedItems(itemKeys: itemKeys, mapName: map.name)
        }
    }
}
