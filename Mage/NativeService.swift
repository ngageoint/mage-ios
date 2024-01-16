//
//  NativeService.swift
//  MAGE
//
//  Created by William Newman on 1/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

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

                return GeocoderResult(name: placemark.name ?? text, address: address, location: placemark.location?.coordinate)
            }
            
            completion(SearchResponse.success(type: .geocoder, results: results))
        }
    }
}
