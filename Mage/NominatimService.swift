//
//  NominatimService.swift
//  MAGE
//
//  Created by William Newman on 12/5/23.
//  Copyright © 2023 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class NominatimService {
    func search(url: String, text: String, region: MKCoordinateRegion? = nil, completion: @escaping ((SearchResponse) -> Void)) {
        let manager = MageSessionManager.shared();
        
        var parameters: [String : String] = [
            "q" : text,
            "limit": "10",
            "addressdetails": "1",
            "format": "geojson"
        ]
        
        if let region = region {
            let minLongitude = region.center.longitude - region.span.longitudeDelta
            let maxLongitude = region.center.longitude + region.span.longitudeDelta
            let minLatitude = region.center.latitude - region.span.latitudeDelta
            let maxLatitude = region.center.latitude + region.span.latitudeDelta
            parameters["viewbox"] = "\(minLongitude), \(minLatitude), \(maxLongitude), \(maxLatitude)"
        }
        
        let task = manager?.get_TASK(url, parameters: parameters, progress: nil, success: { task, response in
            print("success")
            if let featureCollection = response as? [AnyHashable : Any]  {
                let results: [GeocoderResult] = (featureCollection["features"] as? [[AnyHashable: Any]])?.map({ feature in
                    let properties = feature["properties"] as? [AnyHashable: Any]
                    let name = properties?["name"] as? String ?? text
                    let address: String? = properties?["display_name"] as? String
                    let geometry = GeometryDeserializer.parseGeometry(json: feature["geometry"] as? [AnyHashable : Any])
                    let location = geometry?.degreesCentroid().map { centroid in
                        CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue)
                    }
                    
                    return GeocoderResult(name: name, address: address, location: location)
                }) ?? []
                
                completion(SearchResponse.success(type: .geocoder, results: results))

            } else {
                completion(SearchResponse.error(message: "Error parsing geocoder results."));
            }
        }, failure: { task, error in
            print("Error accessing place name server, please try again later.")
        })
        
        manager?.addTask(task);
    }
}
