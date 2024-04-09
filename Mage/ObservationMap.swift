//
//  ObservationMap.swift
//  MAGE
//
//  Created by Daniel Barela on 4/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

class ObservationMap: MapMixin {
    static let MAP_STATE_KEY = "FetchRequestMixinObservationMapDateUpdated"
    let OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID = "OBSERVATION_ICON"
    var cancellable = Set<AnyCancellable>()

    var lastChange: Date?
    var overlays: [MKOverlay] = []
    var annotations: [MKAnnotation] = []
    var scheme: MDCContainerScheming?
    var mapState: MapState? {
        didSet {
            if let mapState = mapState {
                refreshMixin(mapState: mapState)
            }
        }
    }
    var mapFeatureRepository: MapFeatureRepository? {
        didSet {
            if let mapState = mapState {
                refreshMixin(mapState: mapState)
            }
        }
    }

    func refreshMixin(mapState: MapState) {
        if mapFeatureRepository != nil {
            DispatchQueue.main.async {
                self.mapState?.mixinStates[
                    ObservationMap.MAP_STATE_KEY
                ] = Date()
            }
        }
    }

    func applyTheme(scheme: MDCContainerScheming?) {
        self.scheme = scheme
    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        self.mapState = mapState
        updateMixin(mapView: mapView, mapState: mapState)
        mapState.objectWillChange
            .makeConnectable()
            .autoconnect()
            .sink { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    if let mapState = self?.mapState {
                        self?.updateMixin(mapView: mapView, mapState: mapState)
                    }
                }
            }
            .store(in: &cancellable)
    }

    func removeMixin(mapView: MKMapView, mapState: MapState) {
        for overlay in overlays {
            mapView.removeOverlay(overlay)
        }
        mapView.removeAnnotations(annotations)
    }

    func cleanupMixin() {
        cancellable.removeAll()
    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {
        let stateKey = ObservationMap.MAP_STATE_KEY
        if lastChange == nil
            || lastChange != mapState.mixinStates[stateKey] as? Date {
            lastChange = mapState.mixinStates[stateKey] as? Date ?? Date()

            if mapState.mixinStates[stateKey] as? Date == nil {
                DispatchQueue.main.async {
                    mapState.mixinStates[stateKey] = self.lastChange
                }
            }
            for overlay in overlays {
                mapView.removeOverlay(overlay)
            }
            mapView.removeAnnotations(annotations)
            overlays = []
            annotations = []
            Task {
                if let mapFeatureRepository = mapFeatureRepository {
                    await addFeatures(features: mapFeatureRepository.getAnnotationsAndOverlays(), mapView: mapView)
                }
            }
        }
    }

    func addFeatures(features: AnnotationsAndOverlays, mapView: MKMapView) async {
        await MainActor.run {
            mapView.addAnnotations(features.annotations)
            mapView.showAnnotations(features.annotations, animated: true)
            mapView.addOverlays(features.overlays)
            annotations = features.annotations
            overlays = features.overlays
        }
    }

    func viewForAnnotation(annotation: any MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? ObservationMapItemAnnotation else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)

        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView?.isEnabled = true
        }

        if let iconPath = annotation.mapItem.iconPath, let annotationView = annotationView {
            let image = ObservationImage.imageAtPath(imagePath: iconPath)
            annotationView.image = image
            annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height/2.0))
            annotationView.accessibilityLabel = "Observation"
            annotationView.accessibilityValue = "Observation"
            annotationView.displayPriority = .required
            annotationView.canShowCallout = true
        }
        return annotationView
    }

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? ObservationAccuracy {
            let renderer = ObservationAccuracyRenderer(overlay: overlay)
            if let scheme = scheme {
                renderer.applyTheme(withContainerScheme: scheme)
            }
            return renderer
        }
        return nil
    }
}
