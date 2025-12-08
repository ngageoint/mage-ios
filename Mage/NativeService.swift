//
//  NativeService.swift
//  MAGE
//
//  Created by William Newman on 1/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class NativeService {
    func search(text: String, region: MKCoordinateRegion? = nil, completion: @escaping ((SearchResponse) -> Void)) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch.init(request: request)
        search.start { (response, error) in
            guard let response = response else {
                completion(SearchResponse.error(message: "Problem executing search."))
                return
            }
            
            let results = response.mapItems.map { mapItem in
                let placemark = mapItem.placemark
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.subLocality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.countryCode
                ].compactMap { $0 }.joined(separator: ", ")

                // FIXME: Experimental code to explore changing the region displayed so that Fiji can fill the entire map, rather than the ocean at "street view" (wrong zoom level for a country)
//                return GeocoderResult(name: placemark.name ?? text, address: address, location: placemark.location?.coordinate)
                var result = GeocoderResult(name: placemark.name ?? text, address: address, location: placemark.location?.coordinate)
//                result.region = placemark.region
                
                
                
//                var itemRegion: MKCoordinateRegion? = nil
                    
                if let circularRegion = placemark.region as? CLCircularRegion { // FIXME: CLCircularRegion deprecated use CLCircularGeographicCondition on iOS 17+ (dependent on upping the min version for next release)
                        // Convert the circle's radius (meters) to a Map Span (degrees)
                        // Rule of thumb: 1 degree of latitude is ~111,000 meters
                        let diameter = circularRegion.radius * 2.0
                        let degrees = diameter / 111000.0
                        
                        // Add a little padding (1.2x)
                        let span = MKCoordinateSpan(latitudeDelta: degrees * 1.5, longitudeDelta: degrees * 1.5)
                        result.region = MKCoordinateRegion(center: placemark.coordinate, span: span)
                    }
                
                return result
            }
            
            completion(SearchResponse.success(type: .geocoder, results: results))
        }
    }
}
