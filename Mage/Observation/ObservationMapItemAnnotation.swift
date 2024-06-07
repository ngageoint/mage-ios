//
//  ObservationMapItemAnnotation.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition
import MapFramework

class ObservationMapItemAnnotation: DataSourceAnnotation {
    var mapItem: ObservationMapItem
    var title: String?
    var subtitle: String?
    
    override var dataSource: any DataSourceDefinition {
        get {
            DataSources.observation
        }
        set { }
    }

    init(mapItem: ObservationMapItem) {
        self.mapItem = mapItem
        let itemKey = mapItem.observationLocationId?.absoluteString ?? ""
        if let point = mapItem.geometry?.centroid() {
            super.init(coordinate: CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue), itemKey: itemKey)
        } else {
            super.init(coordinate: kCLLocationCoordinate2DInvalid, itemKey: itemKey)
        }
        self.id = mapItem.observationLocationId?.absoluteString ?? UUID().uuidString
    }
}
