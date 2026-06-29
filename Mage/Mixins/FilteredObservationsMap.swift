//
//  ObservationsMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import GeoPackage

protocol FilteredObservationsMap: AnyObject {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var filteredObservationsMapMixin: FilteredObservationsMapMixin? { get set }
}

class FilteredObservationsMapMixin: NSObject, MapMixin {
    weak var filteredObservationsMap: FilteredObservationsMap?
    var mapAnnotationFocusedObserver: AnyObject?
    var user: User?
    
    var enlargedObservationView: MKAnnotationView?
    var selectedObservationAccuracy: MKOverlay?
    
    var observations: Observations?
    var mapObservationManager: MapObservationManager
    private var pointAnnotationsByObjectID: [NSManagedObjectID: ObservationAnnotation] = [:]
    private var lineObservationsByObjectID: [NSManagedObjectID: StyledPolyline] = [:]
    private var polygonObservationsByObjectID: [NSManagedObjectID: StyledPolygon] = [:]
    private var objectIDByRemoteID: [String: NSManagedObjectID] = [:]
    var lineObservations: [StyledPolyline] { Array(lineObservationsByObjectID.values) }
    var polygonObservations: [StyledPolygon] { Array(polygonObservationsByObjectID.values) }
    
    init(filteredObservationsMap: FilteredObservationsMap, user: User? = nil) {
        self.filteredObservationsMap = filteredObservationsMap
        self.user = user
        mapObservationManager = MapObservationManager(mapView: filteredObservationsMap.mapView)
    }
    
    func cleanupMixin() {
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver, name: .MapAnnotationFocused, object: nil)
        }
        mapAnnotationFocusedObserver = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterKey))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterUnitKey))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterNumberKey))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.hideObservations))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.importantFilterKey))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.favoritesFilterKey))
        
        observations?.delegate = nil
        observations = nil
        pointAnnotationsByObjectID.removeAll()
        lineObservationsByObjectID.removeAll()
        polygonObservationsByObjectID.removeAll()
        objectIDByRemoteID.removeAll()
    }
    
    func setupMixin() {
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterUnitKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterNumberKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.hideObservations), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.importantFilterKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.favoritesFilterKey), options: [.new], context: nil)
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notificationObject = (notification.object as? MapAnnotationFocusedNotification), notificationObject.mapView == self?.filteredObservationsMap?.mapView {
                self?.focusAnnotation(annotation: notificationObject.annotation)
            } else if notification.object == nil {
                self?.focusAnnotation(annotation: nil)
            }
        }
        NotificationCenter.default.addObserver(forName: .MAGEFormFetched, object: nil, queue: .main) { [weak self] notification in
            if let event: Event = notification.object as? Event {
                if event.remoteId == Server.currentEventId() {
                    self?.addFilteredObservations()
                }
            }
        }
        addFilteredObservations()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        addFilteredObservations()
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }

    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        let screenPercentage = UserDefaults.standard.shapeScreenClickPercentage
        let tolerance = (self.filteredObservationsMap?.mapView?.visibleMapRect.size.width ?? 0) * Double(screenPercentage)
        
        var annotations: [Any] = []
        for lineObservation in lineObservations {
            if lineHitTest(lineObservation: lineObservation, location: location, tolerance: tolerance) {
               if let observation = lineObservation.observation {
                    annotations.append(observation)
               }
            }
        }
        for polygonObservation in polygonObservations {
            if polygonHitTest(polygonObservation: polygonObservation, location: location) {
                if let observation = polygonObservation.observation {
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

    /// Perform all work on the main thread
    private func performMapMutation(_ mutation: () -> Void) {
        if Thread.isMainThread {
            mutation()
        } else {
            DispatchQueue.main.sync(execute: mutation)
        }
    }

    /// We need a stable CoreData ID for any geometry, so we can prevent adding duplicates
    private func stableObjectID(for observation: Observation) -> NSManagedObjectID {
        if observation.objectID.isTemporaryID {
            do {
                try observation.managedObjectContext?.obtainPermanentIDs(for: [observation])
            } catch {
                NSLog("Failed to obtain permanent objectID for observation: \(error)")
            }
        }
        return observation.objectID
    }

    private func trackedObjectID(for observation: Observation) -> NSManagedObjectID {
        let objectID = stableObjectID(for: observation)
        if let remoteId = observation.remoteId, let existingObjectID = objectIDByRemoteID[remoteId] {
            return existingObjectID
        }
        return objectID
    }

    private func registerRemoteAlias(objectID: NSManagedObjectID, remoteId: String?) {
        if let remoteId = remoteId {
            objectIDByRemoteID[remoteId] = objectID
        }
    }

    private func unregisterRemoteAlias(objectID: NSManagedObjectID, remoteId: String?) {
        if let remoteId = remoteId, objectIDByRemoteID[remoteId] == objectID {
            objectIDByRemoteID.removeValue(forKey: remoteId)
        }
    }

    private func removeTrackedObservation(objectID: NSManagedObjectID, remoteId: String?) {
        if let annotation = pointAnnotationsByObjectID.removeValue(forKey: objectID) {
            filteredObservationsMap?.mapView?.removeAnnotation(annotation)
            unregisterRemoteAlias(objectID: objectID, remoteId: annotation.observationId ?? remoteId)
            return
        }

        if let polyline = lineObservationsByObjectID.removeValue(forKey: objectID) {
            filteredObservationsMap?.mapView?.removeOverlay(polyline)
            unregisterRemoteAlias(objectID: objectID, remoteId: polyline.observationRemoteId ?? remoteId)
            return
        }

        if let polygon = polygonObservationsByObjectID.removeValue(forKey: objectID) {
            filteredObservationsMap?.mapView?.removeOverlay(polygon)
            unregisterRemoteAlias(objectID: objectID, remoteId: polygon.observationRemoteId ?? remoteId)
        }
    }
    
    func updateObservation(observation: Observation, animated: Bool = false, zoom: Bool = false) {
        let objectID = stableObjectID(for: observation)
        deleteObservation(observation: observation)
        guard let geometry = observation.geometry else {
            return
        }

        performMapMutation {
            if geometry.geometryType == .POINT {
                let annotation = ObservationAnnotation(observation: observation, geometry: geometry)
                annotation.animateDrop = animated
                pointAnnotationsByObjectID[objectID] = annotation
                registerRemoteAlias(objectID: objectID, remoteId: observation.remoteId)
                filteredObservationsMap?.mapView?.addAnnotation(annotation)
            } else {
                let style = ObservationShapeStyleParser.style(of: observation)
                let shapeConverter = GPKGMapShapeConverter()
                let shape = shapeConverter?.toShape(with: geometry)
                shapeConverter?.close()

                if let mkpolyline = shape?.shape as? MKPolyline {
                    let styledPolyline = StyledPolyline.create(polyline: mkpolyline)
                    styledPolyline.lineColor = style?.strokeColor ?? .black
                    styledPolyline.lineWidth = style?.lineWidth ?? 1
                    styledPolyline.observationRemoteId = observation.remoteId
                    styledPolyline.observation = observation
                    lineObservationsByObjectID[objectID] = styledPolyline
                    registerRemoteAlias(objectID: objectID, remoteId: observation.remoteId)
                    filteredObservationsMap?.mapView?.addOverlay(styledPolyline)
                } else if let mkpolygon = shape?.shape as? MKPolygon {
                    let styledPolygon = StyledPolygon.create(polygon: mkpolygon)
                    styledPolygon.lineColor = style?.strokeColor ?? .black
                    styledPolygon.lineWidth = style?.lineWidth ?? 1
                    styledPolygon.fillColor = style?.fillColor ?? .clear
                    styledPolygon.observation = observation
                    styledPolygon.observationRemoteId = observation.remoteId
                    polygonObservationsByObjectID[objectID] = styledPolygon
                    registerRemoteAlias(objectID: objectID, remoteId: observation.remoteId)
                    filteredObservationsMap?.mapView?.addOverlay(styledPolygon)
                }
            }
        }
        if zoom {
            zoomAndCenterMap(observation: observation)
        }
    }
    
    func deleteObservation(observation: Observation) {
        let objectID = trackedObjectID(for: observation)
        performMapMutation {
            removeTrackedObservation(objectID: objectID, remoteId: observation.remoteId)
        }
    }
    
    func zoomAndCenterMap(observation: Observation?) {
        if let mapView = filteredObservationsMap?.mapView, let viewRegion = observation?.viewRegion(mapView: mapView) {
            mapView.setRegion(viewRegion, animated: true)
        }
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let observationAnnotation = annotation as? ObservationAnnotation else {
            return nil
        }
        
        let annotationView = observationAnnotation.viewForAnnotation(on: mapView, scheme: filteredObservationsMap?.scheme ?? globalContainerScheme())
        
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
                filteredObservationsMap?.mapView?.removeOverlay(selectedObservationAccuracy)
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
            filteredObservationsMap?.mapView?.removeOverlay(selectedObservationAccuracy)
        }
        
        enlargedObservationView = annotationView
        if let accuracy = observation.properties?[ObservationKey.accuracy.key] as? NSNumber,
           let coordinate = observation.location?.coordinate
        {
            selectedObservationAccuracy = ObservationAccuracy(center: coordinate, radius: CLLocationDistance(truncating: accuracy))
            filteredObservationsMap?.mapView?.addOverlay(selectedObservationAccuracy!)
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            annotationView.centerOffset = CGPoint(x: 0, y: -(annotationView.image?.size.height ?? 0))
        } completion: { success in
        }
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? ObservationAccuracy {
            let renderer = ObservationAccuracyRenderer(overlay: overlay)
            if let scheme = filteredObservationsMap?.scheme {
                renderer.applyTheme(withContainerScheme: scheme)
            }
            return renderer
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
