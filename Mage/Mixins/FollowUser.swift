//
//  FollowUser.swift
//  MAGE
//
//  Created by Daniel Barela on 2/11/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework

protocol FollowUser {
    var mapView: MKMapView? { get set }
    var followUserMapMixin: FollowUserMapMixin? { get set }
}

class FollowUserMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var _followedUser: User?
    var scheme: MDCContainerScheming?
    var fetchedResultsController: NSFetchedResultsController<Location>?
    var gpsFetchedResultsController: NSFetchedResultsController<GPSLocation>?

    var user: User? {
        get {
            return _followedUser
        }
        set {
            _followedUser = newValue
            followUser(user: newValue)
        }
    }
    
    init(followUser: FollowUser, user: User? = nil, scheme: MDCContainerScheming?) {
        self.mapView = followUser.mapView
        self.scheme = scheme
        self._followedUser = user
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        if _followedUser != nil {
            followUser(user: _followedUser)
        }
    }
    
    func cleanupMixin() {
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil
        gpsFetchedResultsController?.delegate = nil
        gpsFetchedResultsController = nil
        _followedUser = nil
    }
    
    func followUser(user: User?) {
        _followedUser = user
        
        guard let user = user else {
            // stop following
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
            gpsFetchedResultsController?.delegate = nil
            gpsFetchedResultsController = nil
            _followedUser = nil
            return
        }
        
        // This is me
        if UserDefaults.standard.currentUserId == user.remoteId {
            let fetchRequest = GPSLocation.fetchRequest()
            fetchRequest.predicate = NSPredicate(value: true)
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: GPSLocationKey.timestamp.key, ascending: true)]
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            
            guard let context = context else { return }
            
            gpsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            gpsFetchedResultsController?.delegate = self
            do {
                try gpsFetchedResultsController?.performFetch()
            } catch {
                let fetchError = error as NSError
                print("Unable to Perform Fetch Request")
                print("\(fetchError), \(fetchError.localizedDescription)")
            }
            if let fetchedObjects = gpsFetchedResultsController?.fetchedObjects, !fetchedObjects.isEmpty, let cllocation = fetchedObjects[0].cllocation {
                zoomAndCenterMap(cllocation: cllocation)
            }
        } else {
            let fetchRequest = Location.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "user = %@", user)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            
            guard let context = context else { return }
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController?.delegate = self
            do {
                try fetchedResultsController?.performFetch()
            } catch {
                let fetchError = error as NSError
                print("Unable to Perform Fetch Request")
                print("\(fetchError), \(fetchError.localizedDescription)")
            }
            if let fetchedObjects = fetchedResultsController?.fetchedObjects, !fetchedObjects.isEmpty {
                zoomAndCenterMap(location: fetchedObjects[0])
            }
        }
    }
    
    func zoomAndCenterMap(location: Location?) {
        if let location = location, let cllocation = location.location {
            zoomAndCenterMap(cllocation: cllocation)
        }
    }
    
    func zoomAndCenterMap(cllocation: CLLocation) {
        let latitudeMeters: CLLocationDistance = cllocation.horizontalAccuracy * 2.5;
        let longitudeMeters: CLLocationDistance = cllocation.horizontalAccuracy * 2.5;
        let centerRegion = MKCoordinateRegion(center: cllocation.coordinate, latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
        if let region: MKCoordinateRegion = mapView?.regionThatFits(centerRegion) {
            mapView?.setRegion(region, animated: true)
        }
    }
}

extension FollowUserMapMixin : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("insert")
            if let location = anObject as? Location {
                zoomAndCenterMap(location: location)
            } else if let gpsLocation = anObject as? GPSLocation, let cllocation = gpsLocation.cllocation {
                zoomAndCenterMap(cllocation: cllocation)
            }
        case .delete:
            print("delete")
        case .update:
            print("update")
            if let location = anObject as? Location {
                zoomAndCenterMap(location: location)
            } else if let gpsLocation = anObject as? GPSLocation, let cllocation = gpsLocation.cllocation {
                zoomAndCenterMap(cllocation: cllocation)
            }
        case .move:
            print("...")
        @unknown default:
            print("...")
        }
    }
}
