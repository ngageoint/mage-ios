//
//  Location.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import SimpleFeatures
import MagicalRecord
import ServerDTO

import Persistence

extension Location: Navigable {
    
    static func mostRecentLocationFetchedResultsController(_ user: User, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Location>? {
        let fetchRequest = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user = %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let locationFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        locationFetchedResultsController.delegate = delegate
        do {
            try locationFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        return locationFetchedResultsController
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
    
    @objc public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self.geometryData = SFGeometryUtils.encode(newValue);
            }
        }
    }
    
    @objc public var location: CLLocation? {
        get {
            if let geometry = geometry, let centroid = SFGeometryUtils.centroid(of: geometry) {
                
                let dictionary: [String : Any] = self.properties as? [String : Any] ?? [:]
                return CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue),
                    altitude: dictionary["altitude"] as? CLLocationDistance ?? 0.0,
                    horizontalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    verticalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    timestamp: timestamp ?? Date());
            }
            return CLLocation(latitude: 0, longitude: 0);
        }
    }
    
    @objc public var sectionName: String {
        get {
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd";
            if let timestamp = self.timestamp {
                return dateFormatter.string(from: timestamp)
            }
            return "";
        }
    }
}
