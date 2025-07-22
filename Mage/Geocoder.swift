//
//  Geocoder.swift
//  MAGE
//
//  Created by William Newman on 12/5/23.
//  Copyright © 2023 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import GARS
import MGRS

enum SearchResponseType {
    case mgrs
    case gars
    case geocoder
}

enum SearchResponse {
    case success(type: SearchResponseType, results: [GeocoderResult])
    case error(message: String)
}

class GeocoderResult {
    var name: String
    var address: String? = nil
    var location: CLLocationCoordinate2D? = nil
    
    init(name: String, address: String? = nil, location: CLLocationCoordinate2D? = nil) {
        self.name = name
        self.address = address
        self.location = location
    }
}

protocol PlacenameSearch {
    func search(text: String, region: MKCoordinateRegion?, completion: @escaping ((SearchResponse) -> Void))
}

class Geocoder {
    func search(text: String, region: MKCoordinateRegion? = nil, completion: @escaping ((SearchResponse) -> Void)) {
        if (GARS.isGARS(text)) {
            let point = GARS.parse(text).toCoordinate()
            let result = GeocoderResult(name: "GARS", address: text, location: point)
            completion(SearchResponse.success(type: .gars, results: [result]))
        } else if (MGRS.isMGRS(text)) {
            let point = MGRS.parse(text).toCoordinate()
            let result = GeocoderResult(name: "MGRS", address: text, location: point)
            completion(SearchResponse.success(type: .mgrs, results: [result]))
        } else {
            @Injected(\.settingsRepository)
            var settingsRepository: SettingsRepository
            let settings = settingsRepository.getSettings()
            let searchType = settings?.mapSearchType ?? .none
            switch searchType {
            case .native:
                NativeGeocoder().search(text: text, region: region, completion: completion)
                break
            case .nominatim:
                if let url = settings?.mapSearchUrl {
                    NominatimGeocoder(url: url).search(text: text, region: region, completion: completion)
                }
            default:
                completion(SearchResponse.error(message: "Unsupported search type"))
            }
        }
    }
}

class NativeGeocoder: PlacenameSearch {
    func search(text: String, region: MKCoordinateRegion? = nil, completion: @escaping ((SearchResponse) -> Void)) {
        let service = NativeService()
        service.search(text: text, region: region, completion: completion)
    }
}

class NominatimGeocoder: PlacenameSearch {
    let url: String
    init(url: String) {
        self.url = url
    }
    
    func search(text: String, region: MKCoordinateRegion? = nil, completion: @escaping ((SearchResponse) -> Void)) {
        let service = NominatimService()
        service.search(url: url, text: text, region: region, completion: completion)
    }
}
