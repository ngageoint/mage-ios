//
//  LocationSummaryViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class LocationSummaryViewModel: ObservableObject {
    @Injected(\.locationRepository)
    var repository: LocationRepository
    
    var uri: URL
    @Published
    var location: LocationModel?
    
    // we do not want the date to word break so we replace all spaces with a non word breaking spaces
    var timeText: String? {
        if let itemDate: NSDate = location?.timestamp as NSDate? {
            return itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        return nil
    }
    
    init(uri: URL) {
        self.uri = uri
        repository.observeLocation(locationUri: uri)?
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$location)
    }
}
