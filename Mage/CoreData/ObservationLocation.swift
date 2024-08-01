//
//  ObservationLocation.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class ObservationLocation: NSManagedObject {

    var region: MKCoordinateRegion {
        var center = CLLocationCoordinate2D(
            latitude: maxLatitude - ((maxLatitude - minLatitude) / 2.0),
            longitude: maxLongitude - ((maxLongitude - minLongitude) / 2.0)
        )
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: maxLatitude - minLatitude,
                longitudeDelta: maxLongitude - minLongitude
            )
        )
    }

    public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self.geometryData = SFGeometryUtils.encode(newValue);
            } else {
                self.geometryData = nil
            }
        }
    }

    public var form: Form? {
        get {
            Form.mr_findFirst(byAttribute: "formId", withValue: formId, in: NSManagedObjectContext.mr_default())
        }
    }
}
