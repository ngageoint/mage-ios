//
//  LocationModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct LocationModel {
    var locationUri: URL
    var location: CLLocation?
    var timestamp: Date?
    var coordinate: CLLocationCoordinate2D?
    var eventId: NSNumber?
    
    var userModel: UserModel?
    
    init(location: Location) {
        locationUri = location.objectID.uriRepresentation()
        if let user = location.user {
            userModel = UserModel(user: user)
        }
        self.location = location.location
        timestamp = location.timestamp
        coordinate = location.coordinate
        eventId = location.eventId
    }
}
