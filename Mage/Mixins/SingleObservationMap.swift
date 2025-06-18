//
//  SingleObservationMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/17/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import geopackage_ios

//protocol SingleObservationMap {
//    var mapView: MKMapView? { get set }
//    var singleObservationMapMixin: SingleObservationMapMixin? { get set }
//}

class SingleObservationMapMixin: FilteredObservationsMapMixin {
    var _observation: Observation?
    
    var observation: Observation? {
        get {
            return _observation
        }
        set {
            _observation = newValue
            addFilteredObservations()
        }
    }
    
    init(filteredObservationsMap: FilteredObservationsMap, observation: Observation? = nil) {
        super.init(filteredObservationsMap: filteredObservationsMap, user: nil)
        self._observation = observation
    }
    
    override func addFilteredObservations() {
        if let observations = observations, let fetchedObservations = observations.fetchedResultsController.fetchedObjects as? [Observation] {
            for observation in fetchedObservations {
                deleteObservation(observation: observation)
            }
        }
        
        if let observation = observation {
            observations = Observations(for: observation)
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
    
    override func updateObservation(observation: Observation, animated: Bool = false, zoom: Bool = false) {
        super.updateObservation(observation: observation, animated:animated, zoom: zoom)
        if let selectedObservationAccuracy = selectedObservationAccuracy {
            filteredObservationsMap.mapView?.removeOverlay(selectedObservationAccuracy)
        }
        if let accuracy = observation.properties?[ObservationKey.accuracy.key] as? NSNumber,
           let coordinate = observation.location?.coordinate
        {
            selectedObservationAccuracy = ObservationAccuracy(center: coordinate, radius: CLLocationDistance(truncating: accuracy))
            filteredObservationsMap.mapView?.addOverlay(selectedObservationAccuracy!)
        }
    }
}
