//
//  FilteredUsersMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol FilteredUsersMap {
    var mapView: MKMapView? { get set }
    var filteredUsersMapMixin: FilteredUsersMapMixin? { get set }
    func addFilteredUsers()
}

extension FilteredUsersMap {
    func addFilteredUsers() {
        filteredUsersMapMixin?.addFilteredUsers()
    }
}

class FilteredUsersMapMixin: NSObject, MapMixin {
    var mapAnnotationFocusedObserver: AnyObject?
    var filteredUsersMap: FilteredUsersMap?
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    
    var enlargedLocationView: MKAnnotationView?
    var selectedUserAccuracy: MKOverlay?
    
    var locations: Locations?
    var user: User?
    
    init(filteredUsersMap: FilteredUsersMap, user: User? = nil, scheme: MDCContainerScheming?) {
        self.filteredUsersMap = filteredUsersMap
        self.mapView = filteredUsersMap.mapView
        self.user = user
        self.scheme = scheme
    }
    
    func cleanupMixin() {
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver)
        }
        mapAnnotationFocusedObserver = nil
        
        UserDefaults.standard.removeObserver(self, forKeyPath: "locationtimeFilterKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "locationtimeFilterUnitKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "locationtimeFilterNumberKey")
        UserDefaults.standard.removeObserver(self, forKeyPath: "hidePeople")
        
        locations?.fetchedResultsController.delegate = nil
        locations = nil
    }
    
    func setupMixin() {
        UserDefaults.standard.addObserver(self, forKeyPath: "locationtimeFilterKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "locationtimeFilterUnitKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "locationtimeFilterNumberKey", options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "hidePeople", options: [.new], context: nil)
        
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notificationObject = (notification.object as? MapAnnotationFocusedNotification), notificationObject.mapView == self?.mapView {
                self?.focusAnnotation(annotation: notificationObject.annotation)
            } else if notification.object == nil {
                self?.focusAnnotation(annotation: nil)
            }
        }
        
        addFilteredUsers()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        addFilteredUsers()
        NotificationCenter.default.post(name: .LocationFiltersChanged, object: nil)
    }
    
    func addFilteredUsers() {
        if let locations = locations, let fetchedLocations = locations.fetchedResultsController.fetchedObjects as? [Location] {
            for location in fetchedLocations {
                deleteLocation(location: location)
            }
        }
        
        if let user = user {
            locations = Locations(for: user)
            locations?.delegate = self
        } else if let locations = locations,
           let locationPredicates = Locations.getPredicatesForLocationsForMap() as? [NSPredicate] {
            locations.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: locationPredicates)
        } else {
            locations = Locations.forMap()
            locations?.delegate = self
        }
        
        if let locations = locations {
            do {
                try locations.fetchedResultsController.performFetch()
                updateLocations(locations: locations.fetchedResultsController?.fetchedObjects as? [Location])
            } catch {
                NSLog("Failed to perform fetch in the MapDelegate for locations \(error), \((error as NSError).userInfo)")
            }
        }
    }
    
    func updateLocations(locations: [Location]?) {
        guard let locations = locations else {
            return
        }
        
        for location in locations {
            DispatchQueue.main.async { [weak self] in
                self?.updateLocation(location: location)
            }
        }
    }
    
    func updateLocation(location: Location) {
        guard let coordinate = location.location?.coordinate else {
            return
        }
        
        if let annotation: LocationAnnotation = mapView?.annotations.first(where: { annotation in
            if let annotation = annotation as? LocationAnnotation {
                return annotation.user?.remoteId == location.user?.remoteId
            }
            return false
        }) as? LocationAnnotation {
            annotation.coordinate = coordinate
        } else {
            if let annotation = LocationAnnotation(location: location) {
                mapView?.addAnnotation(annotation)
            }
        }
    }
    
    func deleteLocation(location: Location) {
        let annotation = mapView?.annotations.first(where: { annotation in
            if let annotation = annotation as? LocationAnnotation {
                return annotation.user.remoteId == location.user?.remoteId
            }
            return false
        })
        
        if let annotation = annotation {
            mapView?.removeAnnotation(annotation)
        }
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let locationAnnotation = annotation as? LocationAnnotation,
              let annotationView = locationAnnotation.viewForAnnotation(on: mapView, scheme: scheme ?? globalContainerScheme()) else {
            return nil
        }
        
        // adjust the center offset if this is the enlargedPin
        if (annotationView == self.enlargedLocationView) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            if let image = annotationView.image {
                annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height))
            } else {
                annotationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y * 2.0)
            }
        }
        annotationView.canShowCallout = false;
        annotationView.isEnabled = false;
        annotationView.accessibilityLabel = "Location Annotation \(locationAnnotation.user?.objectID.uriRepresentation().absoluteString ?? "")";
        return annotationView;
    }
    
    func focusAnnotation(annotation: MKAnnotation?) {
        guard let annotation = annotation as? LocationAnnotation,
              let _ = annotation.user,
              let annotationView = annotation.view else {
                  if let selectedUserAccuracy = selectedUserAccuracy {
                      mapView?.removeOverlay(selectedUserAccuracy)
                      self.selectedUserAccuracy = nil
                  }
                  if let enlargedLocationView = enlargedLocationView {
                      // shrink the old focused view
                      UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                          enlargedLocationView.transform = enlargedLocationView.transform.scaledBy(x: 0.5, y: 0.5)
                          if let image = enlargedLocationView.image {
                              enlargedLocationView.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                          } else {
                              enlargedLocationView.centerOffset = CGPoint(x: 0, y: enlargedLocationView.centerOffset.y / 2.0)
                          }
                      } completion: { success in
                      }
                      self.enlargedLocationView = nil
                  }
                  return
              }
        
        if annotationView == enlargedLocationView {
            // already focused ignore
            return
        } else if let enlargedLocationView = enlargedLocationView {
            // shrink the old focused view
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                enlargedLocationView.transform = enlargedLocationView.transform.scaledBy(x: 0.5, y: 0.5)
                if let image = annotationView.image {
                    enlargedLocationView.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                } else {
                    enlargedLocationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y / 2.0)
                }
            } completion: { success in
            }
        }
        
        if let selectedUserAccuracy = selectedUserAccuracy {
            mapView?.removeOverlay(selectedUserAccuracy)
        }

        enlargedLocationView = annotationView
        let accuracy = annotation.location.horizontalAccuracy
        let coordinate = annotation.location.coordinate
        selectedUserAccuracy = LocationAccuracy(center: coordinate, radius: accuracy)
        mapView?.addOverlay(selectedUserAccuracy!)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            if let image = annotationView.image {
                annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height))
            } else {
                annotationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y * 2.0)
            }
        } completion: { success in
        }
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? LocationAccuracy {
            return LocationAccuracyRenderer(overlay: overlay)
        }
        return nil
    }
}

extension FilteredUsersMapMixin : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let location = anObject as? Location else {
            return
        }
        switch(type) {
            
        case .insert:
            self.updateLocation(location: location)
        case .delete:
            self.deleteLocation(location: location)
        case .move:
            self.updateLocation(location: location)
        case .update:
            self.updateLocation(location: location)
        @unknown default:
            break
        }
    }
}
