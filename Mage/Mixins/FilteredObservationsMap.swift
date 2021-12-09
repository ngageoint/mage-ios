//
//  ObservationsMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol FilteredObservationsMap {
    var mapView: MKMapView? { get set }
    var filteredObservationsMapMixin: FilteredObservationsMapMixin? { get set }
    func addFilteredObservations()
}

extension FilteredObservationsMap {
    
    func addFilteredObservations() {
        filteredObservationsMapMixin?.addFilteredObservations()
    }
}

class FilteredObservationsMapMixin: NSObject, NSFetchedResultsControllerDelegate, MapMixin {
    
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    
    var enlargedObservationView: MKAnnotationView?
    var selectedObservationAccuracy: MKOverlay?
    
    var observations: Observations?
    var mapObservationManager: MapObservationManager
    
    init(mapView: MKMapView, scheme: MDCContainerScheming?) {
        self.mapView = mapView
        self.scheme = scheme
        mapObservationManager = MapObservationManager(mapView: mapView)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .MapAnnotationFocused, object: nil)
    }
    
    func setupMixin() {
        NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notification = notification.object as? MapAnnotationFocusedNotification {
                self?.focusAnnotation(annotation: notification.annotation)
            }
        }
        addFilteredObservations()
    }
    
    func addFilteredObservations() {
        if let observations = observations,
           let observationPredicates = Observations.getPredicatesForObservationsForMap() as? [NSPredicate] {
            observations.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: observationPredicates)
            
        } else {
            observations = Observations.forMap()
            observations?.delegate = self
        }
        
        if let observations = observations {
            do {
                try observations.fetchedResultsController.performFetch()
                updateObservations(observations: observations.fetchedResultsController.fetchedObjects as? [Observation])
            } catch {
                NSLog("Failed to perform fetch in the MapDelegate for observations \(error), \((error as NSError).userInfo)")
            }
        }
    }
    
    func updateObservations(observations: [Observation]?) {
        guard let observations = observations else {
            return
        }

        for observation in observations {
            DispatchQueue.main.async { [weak self] in
                self?.updateObservation(observation: observation)
            }
        }
    }
    
    func updateObservation(observation: Observation, animated: Bool = false) {
        if let geometry = observation.geometry {
            mapObservationManager.addToMap(with: observation, andAnimateDrop: animated)
        }
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let observationAnnotation = annotation as? ObservationAnnotation else {
            return nil
        }
        
        let annotationView = observationAnnotation.viewForAnnotation(on: mapView, scheme: scheme ?? globalContainerScheme())
        
        // adjiust the center offset if this is the enlargedPin
//        if (annotationView == self.enlargedPin) {
//            annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height));
//        }
        annotationView.canShowCallout = false;
//        annotationView.hidden = self.hideObservations;
//        annotationView.accessibilityElementsHidden = self.hideObservations;
        annotationView.isEnabled = false;
        annotationView.accessibilityLabel = "Observation Annotation \(observationAnnotation.observation?.objectID.uriRepresentation().absoluteString ?? "")";
        return annotationView;
    }
    
    func focusAnnotation(annotation: MKAnnotation?) {
        guard let annotation = annotation as? ObservationAnnotation,
              let observation = annotation.observation,
              let annotationView = annotation.view else {
            if let selectedObservationAccuracy = selectedObservationAccuracy {
                mapView?.removeOverlay(selectedObservationAccuracy)
                self.selectedObservationAccuracy = nil
            }
            if let enlargedObservationView = enlargedObservationView {
                // shrink the old focused view
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                  enlargedObservationView.transform = enlargedObservationView.transform.scaledBy(x: 0.5, y: 0.5)
                  enlargedObservationView.centerOffset = CGPoint(x: 0, y: -((enlargedObservationView.image?.size.height ?? 0.0) / 2.0))
                } completion: { success in
                }
                self.enlargedObservationView = nil
            }
            return
        }
        
        if annotationView == enlargedObservationView {
            // already focused ignore
            return
        } else if let enlargedObservationView = enlargedObservationView {
            // shrink the old focused view
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                enlargedObservationView.transform = enlargedObservationView.transform.scaledBy(x: 0.5, y: 0.5)
                enlargedObservationView.centerOffset = CGPoint(x: 0, y: -((enlargedObservationView.image?.size.height ?? 0.0) / 2.0))
            } completion: { success in
            }
        }
        
        if let selectedObservationAccuracy = selectedObservationAccuracy {
            mapView?.removeOverlay(selectedObservationAccuracy)
        }
        
        enlargedObservationView = annotationView
        if let accuracy = observation.properties?[ObservationKey.accuracy.key] as? NSNumber,
           let coordinate = observation.location?.coordinate
        {
            selectedObservationAccuracy = ObservationAccuracy(center: coordinate, radius: CLLocationDistance(truncating: accuracy))
            mapView?.addOverlay(selectedObservationAccuracy!)
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            annotationView.centerOffset = CGPoint(x: 0, y: -(annotationView.image?.size.height ?? 0))
        } completion: { success in
        }
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        print("renderer for overlay \(overlay)")
        if let overlay = overlay as? ObservationAccuracy {
            return ObservationAccuracyRenderer(overlay: overlay)
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            if let overlay = overlay as? StyledPolygon {
                renderer.fillColor = overlay.fillColor
                renderer.strokeColor = overlay.lineColor
                renderer.lineWidth = overlay.lineWidth
            } else {
                renderer.strokeColor = .black
                renderer.lineWidth = 1
            }
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            if let overlay = overlay as? StyledPolyline {
                renderer.strokeColor = overlay.lineColor
                renderer.lineWidth = overlay.lineWidth
            } else {
                renderer.strokeColor = .black
                renderer.lineWidth = 1
            }
            return renderer
        }
        return nil
    }
}
