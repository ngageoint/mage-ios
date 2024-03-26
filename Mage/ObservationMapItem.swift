//
//  ObservationMapItem.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import sf_ios

struct ObservationMapItem {
    var observationId: URL?
    var geometry: SFGeometry?
    var iconPath: String?
    var formId: Int64?
}

extension ObservationMapItem {
    init(observation: ObservationLocation) {
        self.observationId = observation.observation?.objectID.uriRepresentation()
        self.geometry = observation.geometry
        if let observation = observation.observation {
            self.iconPath = ObservationImage.imageName(observation: observation)
        }
        self.formId = observation.formId
    }
}
