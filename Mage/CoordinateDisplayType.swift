//
//  CoordinateDisplayType.swift
//  Marlin
//
//  Created by Daniel Barela on 2/29/24.
//

import Foundation
import MapKit
import GARS
import MGRS
import CLLocationCoordinate2DExtensions

enum CoordinateDisplayType: Int, CustomStringConvertible {
    case latitudeLongitude, degreesMinutesSeconds, mgrs, gars

    var description: String {
        switch self {
        case .latitudeLongitude:
            return "Latitude, Longitude"
        case .degreesMinutesSeconds:
            return "Degrees, Minutes, Seconds"
        case .mgrs:
            return "Military Grid Reference System"
        case .gars:
            return "Global Area Reference System"
        }
    }

    func format(coordinate: CLLocationCoordinate2D) -> String {
        switch UserDefaults.standard.coordinateDisplay {
        case .latitudeLongitude:
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            return """
            \(formatter.string(for: coordinate.latitude) ?? ""), \
            \(formatter.string(for: coordinate.longitude) ?? "")
            """
        case .degreesMinutesSeconds:
            return """
            \(CLLocationCoordinate2D.latitudeDMSString(coordinate: coordinate.latitude)), \
            \(CLLocationCoordinate2D.longitudeDMSString(coordinate: coordinate.longitude))
            """
        case .gars:
            if CLLocationCoordinate2DIsValid(coordinate) {
                return GARS.from(coordinate).coordinate()
            }
            return ""
        case .mgrs:
            if CLLocationCoordinate2DIsValid(coordinate) {
                return MGRS.from(coordinate).coordinate()
            }
            return ""
        }
    }
}

extension CLLocationCoordinate2D {

    func format() -> String {
        switch UserDefaults.standard.coordinateDisplay {
        case .latitudeLongitude:
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            return "\(formatter.string(for: self.latitude) ?? "")°, \(formatter.string(for: self.longitude) ?? "")°"
        case .degreesMinutesSeconds:
            return """
            \(CLLocationCoordinate2D.latitudeDMSString(coordinate: self.latitude)), \
            \(CLLocationCoordinate2D.longitudeDMSString(coordinate: self.longitude))
            """
        case .gars:
            return GARS.from(self).coordinate()
        case .mgrs:
            return MGRS.from(self).coordinate()
        }
    }
}
