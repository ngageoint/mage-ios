//
//  CLCoordinate2DExtensions.swift
//  MAGE
//
//  Created by Daniel Barela on 4/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension CLLocationCoordinate2D {
    func bearing(to point: CLLocationCoordinate2D) -> Double {
        func degreesToRadians(_ degrees: Double) -> Double { return degrees * Double.pi / 180.0 }
        func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / Double.pi }
        
        let lat1 = degreesToRadians(latitude)
        let lon1 = degreesToRadians(longitude)
        
        let lat2 = degreesToRadians(point.latitude);
        let lon2 = degreesToRadians(point.longitude);
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x);
        
        let degrees = radiansToDegrees(radiansBearing)
        if (degrees > 360) {
            return degrees - 360;
        }
        if (degrees < 0) {
            return degrees + 360;
        }
        
        return degrees;
    }
    
    public func toDisplay(short: Bool = false) -> String {
        if UserDefaults.standard.locationDisplay == .mgrs {
            return GridSystems.mgrs(self)
        } else if UserDefaults.standard.locationDisplay == .dms {
            return "\(LocationUtilities.latitudeDMSString(coordinate: self.latitude)), \(LocationUtilities.longitudeDMSString(coordinate: self.longitude))"
        } else if UserDefaults.standard.locationDisplay == .gars {
            return GridSystems.gars(self)
        } else {
            return String(format: "%.4f, %.4f", self.latitude, self.longitude)
        }
    }
    
    // takes one coordinate and translates it into a CLLocationDegrees
    // returns nil if nothing can be parsed
    static func parse(coordinate: String?, enforceLatitude: Bool = false) -> CLLocationDegrees? {
        guard let coordinate = coordinate else {
            return nil
        }
        
        let normalized = coordinate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // check if it is a number and that number could be a valid latitude or longitude
        // could either be a decimal or a whole number representing lat/lng or a DDMMSS.sss number representing degree minutes seconds
        if let decimalDegrees = Double(normalized) {
            // if either of these are true, parse it as a regular latitude longitude
            if (!enforceLatitude && decimalDegrees >= -180 && decimalDegrees <= 180)
                || (enforceLatitude && decimalDegrees >= -90 && decimalDegrees <= 90) {
                return CLLocationDegrees(decimalDegrees)
            }
        }
        
        // try to just parse it as DMS
        let dms = LocationUtilities.parseDMS(coordinate: normalized)
        if let degrees = dms.degrees {
            var coordinateDegrees = Double(degrees)
            if let minutes = dms.minutes {
                coordinateDegrees += Double(minutes) / 60.0
            }
            if let seconds = dms.seconds {
                coordinateDegrees += Double(seconds) / 3600.0
            }
            if let direction = dms.direction {
                if direction == "S" || direction == "W" {
                    coordinateDegrees = -coordinateDegrees
                }
            }
            return CLLocationDegrees(coordinateDegrees)
        }
        
        return nil
    }
    
    // splits the string into possibly two coordinates with all spaces removed
    // no further normalization takes place
    static func splitCoordinates(coordinates: String?) -> [String] {
        var split: [String] = []
        
        guard let coordinates = coordinates else {
            return split
        }
        
        // trim whitespace from the start and end of the string
        let coordinatesToParse = coordinates.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // if there is a comma, split on that
        if coordinatesToParse.firstIndex(of: ",") != nil {
            return coordinatesToParse.split(separator: ",").map { splitString in
                return "\(splitString)".components(separatedBy: .whitespacesAndNewlines).joined()
            }
        }
        
        // check if there are any direction letters
        let firstDirectionIndex = coordinatesToParse.firstIndex { character in
            let uppercase = character.uppercased()
            return uppercase == "N" || uppercase == "S" || uppercase == "E" || uppercase == "W"
        }
        let hasDirection = firstDirectionIndex != nil
        
        // if the string has a direction we can try to split on the dash
        if hasDirection && coordinatesToParse.firstIndex(of: "-") != nil {
            return coordinatesToParse.split(separator: "-").map { splitString in
                return "\(splitString)".components(separatedBy: .whitespacesAndNewlines).joined()
            }
        } else if hasDirection {
            // if the string has a direction but no dash, split on the direction
            let lastDirectionIndex = coordinatesToParse.lastIndex { character in
                let uppercase = character.uppercased()
                return uppercase == "N" || uppercase == "S" || uppercase == "E" || uppercase == "W"
            }
            // the direction will either be at the begining of the string, or the end
            // if the direction is at the begining of the string, use the second index unless there is no second index
            // in which case there is only one coordinate
            if firstDirectionIndex == coordinatesToParse.startIndex {
                if let lastDirectionIndex = lastDirectionIndex, lastDirectionIndex != firstDirectionIndex {
                    split.append("\(coordinatesToParse.prefix(upTo: lastDirectionIndex))")
                    split.append("\(coordinatesToParse.suffix(from: lastDirectionIndex))")
                } else {
                    // only one coordinate
                    split.append(coordinatesToParse)
                }
            } else if lastDirectionIndex == coordinatesToParse.index(coordinatesToParse.endIndex, offsetBy: -1) {
                // if the last direction index is the end of the string use the first index unless the first and last index are the same
                if lastDirectionIndex == firstDirectionIndex {
                    // only one coordinate
                    split.append(coordinatesToParse)
                } else if let firstDirectionIndex = firstDirectionIndex {
                    split.append("\(coordinatesToParse.prefix(upTo: coordinatesToParse.index(firstDirectionIndex, offsetBy: 1)))")
                    split.append("\(coordinatesToParse.suffix(from: coordinatesToParse.index(firstDirectionIndex, offsetBy: 1)))")
                }
            }
        }
        
        // one last attempt to split.  if there is one white space character split on that
        let whitespaceSplit = coordinatesToParse.components(separatedBy: .whitespacesAndNewlines)
        if whitespaceSplit.count <= 2 {
            split = whitespaceSplit
        }
        
        return split.map { splitString in
            return splitString.components(separatedBy: .whitespacesAndNewlines).joined()
        }
    }
    
    // best effort parse of the string passed in
    // returns kCLLocationCoordinate2DInvalid if there is no way to parse
    // If only one of latitude or longitude can be parsed, the returned coordinate will have that value set
    // with the other value being CLLocationDegrees.nan.  longitude will be the default returned value
    static func parse(coordinates: String?) -> CLLocationCoordinate2D {
        var location = CLLocationCoordinate2D(latitude: CLLocationDegrees.nan, longitude: CLLocationDegrees.nan)
        
        let split = CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)
        if split.count == 2 {
            if let latitude = CLLocationCoordinate2D.parse(coordinate: split[0], enforceLatitude: true) {
                location.latitude = latitude
            }
            if let longitude = CLLocationCoordinate2D.parse(coordinate: split[1], enforceLatitude: false) {
                location.longitude = longitude
            }
        } else if split.count == 1 {
            if let coordinate = CLLocationCoordinate2D.parse(coordinate: split[0], enforceLatitude: false) {
                location.longitude = coordinate
            }
            
        }
        
        return location
    }
}
