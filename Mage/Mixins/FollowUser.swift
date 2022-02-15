//
//  FollowUser.swift
//  MAGE
//
//  Created by Daniel Barela on 2/11/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol FollowUser {
    var mapView: MKMapView? { get set }
    var followUserMapMixin: FollowUserMapMixin? { get set }
}

class FollowUserMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var _followedUser: User?
    var scheme: MDCContainerScheming?
    var fetchedResultsController: NSFetchedResultsController<Location>?

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
    
    func setupMixin() {
        if _followedUser != nil {
            followUser(user: _followedUser)
        }
    }
    
    func followUser(user: User?) {
        guard let user = user else {
            // stop following
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
            return
        }
        
        // This is me
        if UserDefaults.standard.currentUserId == user.remoteId {
            let locations: [GPSLocation] = GPSLocation.fetchGPSLocations(limit: 1, context: NSManagedObjectContext.mr_default())
            if (locations.count != 0) {
                let location: GPSLocation = locations[0]
                let centroid: SFPoint = SFGeometryUtils.centroid(of: location.geometry)
                let dictionary: [String : Any] = location.properties as! [String : Any]
                let cllocation = CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: centroid.y as! CLLocationDegrees,
                        longitude: centroid.x as! CLLocationDegrees),
                    altitude: dictionary["altitude"] as! CLLocationDistance,
                    horizontalAccuracy: dictionary["accuracy"] as! CLLocationAccuracy,
                    verticalAccuracy: dictionary["accuracy"] as!CLLocationAccuracy,
                    timestamp: location.timestamp!)
                zoomAndCenterMap(cllocation: cllocation)
            }
        } else {
            let fetchRequest = Location.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "user = %@", user)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
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
        case .delete:
            print("delete")
        case .update:
            print("update")
            zoomAndCenterMap(location: anObject as? Location)
        case .move:
            print("...")
        @unknown default:
            print("...")
        }
    }
}
