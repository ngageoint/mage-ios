//
//  ObservationsMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import geopackage_ios

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

class FilteredObservationsMapMixin: NSObject, MapMixin {
    var mapAnnotationFocusedObserver: AnyObject?

    weak var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    var user: User?
    var observation: Observation?
    
    var enlargedObservationView: MKAnnotationView?
    var selectedObservationAccuracy: MKOverlay?
    
    var observations: Observations?
    var mapObservationManager: MapObservationManager
    var lineObservations: [StyledPolyline] = []
    var polygonObservations: [StyledPolygon] = []
    
    init(mapView: MKMapView, user: User? = nil, observation: Observation? = nil, scheme: MDCContainerScheming?) {
        self.mapView = mapView
        self.scheme = scheme
        self.user = user
        self.observation = observation
        mapObservationManager = MapObservationManager(mapView: mapView)
    }
    
    deinit {
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver, name: .MapAnnotationFocused, object: nil)
        }
        mapAnnotationFocusedObserver = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: "timeFilterKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "timeFilterUnitKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "timeFilterNumberKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "hideObservations")
        UserDefaults.standard.removeObserver(self, forKeyPath: "importantFilterKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "favoritesFilterKey")
    }
    
    func setupMixin() {
        UserDefaults.standard.addObserver(self, forKeyPath: "timeFilterKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "timeFilterUnitKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "timeFilterNumberKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "hideObservations", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "importantFilterKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "favoritesFilterKey", options: [.new], context: nil)
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            self?.focusAnnotation(annotation: (notification.object as? MapAnnotationFocusedNotification)?.annotation)
        }
        addFilteredObservations()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        addFilteredObservations()
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }

    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        let screenPercentage = UserDefaults.standard.shapeScreenClickPercentage
        let tolerance = (self.mapView?.visibleMapRect.size.width ?? 0) * Double(screenPercentage)
        
        var annotations: [Any] = []
        for lineObservation in lineObservations {
            if lineHitTest(lineObservation: lineObservation, location: location, tolerance: tolerance), let observationRemoteId = lineObservation.observationRemoteId {
                if let observation = Observation.mr_findFirst(byAttribute: "remoteId", withValue: observationRemoteId) {
                    annotations.append(observation)
                }
            }
        }
        
        for polygonObservation in polygonObservations {
            if polygonHitTest(polygonObservation: polygonObservation, location: location), let observationRemoteId = polygonObservation.observationRemoteId {
                if let observation = Observation.mr_findFirst(byAttribute: "remoteId", withValue: observationRemoteId) {
                    annotations.append(observation)
                }
            }
        }
        return annotations
    }
    
    func addFilteredObservations() {
        if let observations = observations, let fetchedObservations = observations.fetchedResultsController.fetchedObjects as? [Observation] {
            for observation in fetchedObservations {
                deleteObservation(observation: observation)
            }
        }
        
        if let user = user {
            observations = Observations(for: user)
            observations?.delegate = self
        } else if let observation = observation {
            observations = Observations(for: observation)
            observations?.delegate = self
        } else if let observations = observations,
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
    
    func updateObservation(observation: Observation, animated: Bool = false, zoom: Bool = false) {
        deleteObservation(observation: observation)
        if let geometry = observation.geometry {
            if geometry.geometryType == SF_POINT {
                let annotation = ObservationAnnotation(observation: observation, geometry: geometry)
//                annotation.view.layer.zPosition = CGFloat(observation.timestamp?.timeIntervalSinceReferenceDate ?? 0)
                annotation.animateDrop = animated
                mapView?.addAnnotation(annotation)
            } else {
                let style = ObservationShapeStyleParser.style(of: observation)
                let shapeConverter = GPKGMapShapeConverter()
                let shape = shapeConverter?.toShape(with: geometry)
                if let mkpolyline = shape?.shape as? MKPolyline {
                    let styledPolyline = StyledPolyline.create(with: mkpolyline)
                    styledPolyline.lineColor = style?.strokeColor ?? .black
                    styledPolyline.lineWidth = style?.lineWidth ?? 1
                    styledPolyline.observationRemoteId = observation.remoteId
                    lineObservations.append(styledPolyline)
                    mapView?.addOverlay(styledPolyline)
                } else if let mkpolygon = shape?.shape as? MKPolygon {
                    let styledPolygon = StyledPolygon.create(with: mkpolygon)
                    styledPolygon.lineColor = style?.strokeColor ?? .black
                    styledPolygon.lineWidth = style?.lineWidth ?? 1
                    styledPolygon.fillColor = style?.fillColor ?? .clear
                    styledPolygon.observationRemoteId = observation.remoteId
                    polygonObservations.append(styledPolygon)
                    mapView?.addOverlay(styledPolygon)
                }
            }
        }
        if zoom {
            zoomAndCenterMap(observation: observation)
        }
    }
    
    func deleteObservation(observation: Observation) {
        let annotation = mapView?.annotations.first(where: { annotation in
            if let annotation = annotation as? ObservationAnnotation {
                return annotation.observationId == observation.remoteId
            }
            return false
        })
        
        if let annotation = annotation {
            mapView?.removeAnnotation(annotation)
        } else {
            // it might be a line
            let polyline = lineObservations.first { polyline in
                return polyline.observationRemoteId == observation.remoteId
            }
            
            if let polyline = polyline {
                mapView?.removeOverlay(polyline)
            } else {
                // it might be a polygon
                let polygon = polygonObservations.first { polygon in
                    return polygon.observationRemoteId == observation.remoteId
                }
                
                if let polygon = polygon {
                    mapView?.removeOverlay(polygon)
                }
            }
        }
    }
    
    func zoomAndCenterMap(observation: Observation?) {
        if let mapView = mapView, let viewRegion = observation?.viewRegion(mapView: mapView) {
            mapView.setRegion(viewRegion, animated: true)
        }
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let observationAnnotation = annotation as? ObservationAnnotation else {
            return nil
        }
        
        let annotationView = observationAnnotation.viewForAnnotation(on: mapView, scheme: scheme ?? globalContainerScheme())
        
        // adjiust the center offset if this is the enlargedPin
        if (annotationView == self.enlargedObservationView) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            annotationView.centerOffset = CGPoint(x: 0, y: -(annotationView.image?.size.height ?? 0))
        }
        annotationView.canShowCallout = false;
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
        if let overlay = overlay as? ObservationAccuracy {
            return ObservationAccuracyRenderer(overlay: overlay)
        }
        return nil
    }
}

extension FilteredObservationsMapMixin : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let observation = anObject as? Observation else {
            return
        }
        switch(type) {
            
        case .insert:
            self.updateObservation(observation: observation, animated: true)
        case .delete:
            self.deleteObservation(observation: observation)
        case .move:
            self.updateObservation(observation: observation, animated: false)
        case .update:
            self.updateObservation(observation: observation, animated: false)
        @unknown default:
            break
        }
    }
}
