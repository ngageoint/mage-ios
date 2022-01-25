//
//  CoordinateDisplay.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import mgrs
import CoreLocation

struct DMSCoordinate {
    var degrees: Int?
    var minutes: Int?
    var seconds: Int?
    var direction: String?
}

extension CLLocationCoordinate2D {
    
    public func toDisplay(short: Bool = false) -> String {
        if UserDefaults.standard.locationDisplay == .mgrs {
            return MGRS.mgrSfromCoordinate(self)
        } else if UserDefaults.standard.locationDisplay == .dms {
            return "\(LocationUtilities.latitudeDMSString(coordinate: self.latitude)), \(LocationUtilities.longitudeDMSString(coordinate: self.longitude))"
        } else {
            return String(format: "%.5f, %.5f", self.latitude, self.longitude)
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

class LocationUtilities: NSObject {

    // Need to parse the following formats:
    // 1. 112233N 0112244W
    // 2. N 11 ° 22'33 "- W 11 ° 22'33
    // 3. 11 ° 22'33 "N - 11 ° 22'33" W
    // 4. 11° 22'33 N 011° 22'33 W
    static func parseDMS(coordinate: String, addDirection: Bool = false, latitude: Bool = false) -> DMSCoordinate {
        var dmsCoordinate: DMSCoordinate = DMSCoordinate()
        
        var coordinateToParse = coordinate.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if addDirection {
            // check if the first character is negative
            if coordinateToParse.firstIndex(of: "-") == coordinateToParse.startIndex {
                dmsCoordinate.direction = latitude ? "S" : "W"
            } else {
                dmsCoordinate.direction = latitude ? "N" : "E"
            }
        }
        
        var charactersToKeep = CharacterSet()
        charactersToKeep.formUnion(.decimalDigits)
        charactersToKeep.insert(charactersIn: ".NSEWnsew")
        coordinateToParse = coordinate.components(separatedBy: charactersToKeep.inverted).joined()

        if let direction = coordinateToParse.last {
            // the last character might be a direction not a number
            if let _ = direction.wholeNumberValue {
                
            } else {
                dmsCoordinate.direction = "\(direction)".uppercased()
                coordinateToParse = "\(coordinateToParse.dropLast(1))"
            }
        }
        if let direction = coordinateToParse.first {
            // the first character might be a direction not a number
            if let _ = direction.wholeNumberValue {
                
            } else {
                dmsCoordinate.direction = "\(direction)".uppercased()
                coordinateToParse = "\(coordinateToParse.dropFirst(1))"
            }
        }
        
        // split the numbers before the decimal seconds
        if coordinateToParse.isEmpty {
            return dmsCoordinate
        }
        let split = coordinateToParse.split(separator: ".")
        
        coordinateToParse = "\(split[0])"
        let decimalSeconds = split.count == 2 ? Int(split[1]) : nil
        
        dmsCoordinate.seconds = Int(coordinateToParse.suffix(2))
        coordinateToParse = "\(coordinateToParse.dropLast(2))"
        
        dmsCoordinate.minutes = Int(coordinateToParse.suffix(2))
        dmsCoordinate.degrees = Int(coordinateToParse.dropLast(2))
        
        if dmsCoordinate.degrees == nil {
            if dmsCoordinate.minutes == nil {
                dmsCoordinate.degrees = dmsCoordinate.seconds
                dmsCoordinate.seconds = nil
            } else {
                dmsCoordinate.degrees = dmsCoordinate.minutes
                dmsCoordinate.minutes = dmsCoordinate.seconds
                dmsCoordinate.seconds = nil
            }
        }
        
        if dmsCoordinate.minutes == nil && dmsCoordinate.seconds == nil && decimalSeconds != nil {
            // this would be the case if a decimal degrees was passed in ie 11.123
            let decimal = Double(".\(decimalSeconds ?? 0)") ?? 0.0
            dmsCoordinate.minutes = Int(abs((decimal.truncatingRemainder(dividingBy: 1) * 60.0)))
            let seconds = abs(((decimal.truncatingRemainder(dividingBy: 1) * 60.0).truncatingRemainder(dividingBy: 1) * 60.0))
            dmsCoordinate.seconds = Int(seconds.rounded())
        } else if let decimalSeconds = decimalSeconds {
            // add the decimal seconds to seconds and round
            dmsCoordinate.seconds = Int(Double("\((dmsCoordinate.seconds ?? 0)).\(decimalSeconds)")?.rounded() ?? 0)
        }
        
        if dmsCoordinate.seconds == 60 {
            dmsCoordinate.minutes = (dmsCoordinate.minutes ?? 0) + 1
            dmsCoordinate.seconds = 0
        }
        
        if dmsCoordinate.minutes == 60 {
            dmsCoordinate.degrees = (dmsCoordinate.degrees ?? 0) + 1
            dmsCoordinate.minutes = 0
        }
        
        return dmsCoordinate
    }
    
    @objc public static func validateLatitudeFromDMS(latitude: String?) -> Bool {
        return validateCoordinateFromDMS(coordinate: latitude, latitude: true)
    }
    
    @objc public static func validateLongitudeFromDMS(longitude: String?) -> Bool {
        return validateCoordinateFromDMS(coordinate: longitude, latitude: false)
    }
    
    @objc public static func validateCoordinateFromDMS(coordinate: String?, latitude: Bool) -> Bool {
        guard let coordinate = coordinate else {
            return false
        }
        
        var validCharacters = CharacterSet()
        validCharacters.formUnion(.decimalDigits)
        validCharacters.insert(charactersIn: ".NSEWnsew °\'\"")
        if coordinate.rangeOfCharacter(from: validCharacters.inverted) != nil {
            return false
        }

        var charactersToKeep = CharacterSet()
        charactersToKeep.formUnion(.decimalDigits)
        charactersToKeep.insert(charactersIn: ".NSEWnsew")
        var coordinateToParse = coordinate.components(separatedBy: charactersToKeep.inverted).joined()

        // There must be a direction as the last character
        if let direction = coordinateToParse.last {
            // the last character must be either N or S not a number
            if let _ = direction.wholeNumberValue {
                return false
            } else {
                if latitude && direction.uppercased() != "N" && direction.uppercased() != "S" {
                    return false
                }
                if !latitude && direction.uppercased() != "E" && direction.uppercased() != "W" {
                    return false
                }
                coordinateToParse = "\(coordinateToParse.dropLast(1))"
            }
        } else {
            return false
        }
        
        // split the numbers before the decimal seconds
        let split = coordinateToParse.split(separator: ".")
        if split.isEmpty  {
            return false
        }
        
        coordinateToParse = "\(split[0])"
        
        // there must be either 5 or 6 digits for latitude (1 or 2 degrees, 2 minutes, 2 seconds)
        // or 5, 6, 7 digits for longitude
        if latitude && (coordinateToParse.count < 5 || coordinateToParse.count > 6) {
            return false
        }
        if !latitude && (coordinateToParse.count < 5 || coordinateToParse.count > 7) {
            return false
        }
                
        var decimalSeconds = 0
        
        if split.count == 2 {
            if let decimalSecondsInt = Int(split[1]) {
                decimalSeconds = decimalSecondsInt
            } else {
                return false
            }
        }
                
        let seconds = Int(coordinateToParse.suffix(2))
        coordinateToParse = "\(coordinateToParse.dropLast(2))"
        
        let minutes = Int(coordinateToParse.suffix(2))
        let degrees = Int(coordinateToParse.dropLast(2))
        
        if let degrees = degrees {
            if latitude && (degrees < 0 || degrees > 90) {
                return false
            }
            if !latitude && (degrees < 0 || degrees > 180) {
                return false
            }
        } else {
            return false
        }
        
        if let minutes = minutes, let degrees = degrees {
            if (minutes < 0 || minutes > 59) || (latitude && degrees == 90 && minutes != 0) || (!latitude && degrees == 180 && minutes != 0) {
                return false
            }
        } else {
            return false
        }
        
        if let seconds = seconds, let degrees = degrees {
            if (seconds < 0 || seconds > 59) || (latitude && degrees == 90 && (seconds != 0 || decimalSeconds != 0)) || (!latitude && degrees == 180 && (seconds != 0 || decimalSeconds != 0)) {
                return false
            }
        } else {
            return false
        }
        
        return true
    }
    
    // attempts to parse what was passed in to DDD° MM' SS.sss" (NS) or returns "" if unparsable
    @objc public static func parseToDMSString(_ string: String?, addDirection: Bool = false, latitude: Bool = false) -> String? {
        guard let string = string else {
            return nil
        }

        if string.isEmpty {
            return ""
        }
        
        let parsed = parseDMS(coordinate: string, addDirection: addDirection, latitude: latitude)
        
        let direction = parsed.direction ?? ""
        
        var seconds = ""
        if let parsedSeconds = parsed.seconds {
            seconds = String(format: "%02d", parsedSeconds)
        }
        
        var minutes = ""
        if let parsedMinutes = parsed.minutes {
            minutes = String(format: "%02d", parsedMinutes)
        }
        
        var degrees = ""
        if let parsedDegrees = parsed.degrees {
            degrees = "\(parsedDegrees)"
        }

        if !degrees.isEmpty {
            degrees = "\(degrees)° "
        }
        if !minutes.isEmpty {
            minutes = "\(minutes)\' "
        }
        if !seconds.isEmpty {
            seconds = "\(seconds)\" "
        }
        
        return "\(degrees)\(minutes)\(seconds)\(direction)"
    }
    
    // TODO: update this when non @objc to take an optional and return nil
    @objc public static func latitudeDMSString(coordinate: CLLocationDegrees) -> String {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        nf.minimumIntegerDigits = 2
        
        var latDegrees: Int = Int(coordinate)
        var latMinutes = Int(abs((coordinate.truncatingRemainder(dividingBy: 1) * 60.0)))
        var latSeconds = abs(((coordinate.truncatingRemainder(dividingBy: 1) * 60.0).truncatingRemainder(dividingBy: 1) * 60.0)).rounded()
        if latSeconds == 60 {
            latSeconds = 0
            latMinutes += 1
        }
        if latMinutes == 60 {
            latDegrees += 1
            latMinutes = 0
        }
        return "\(abs(latDegrees))° \(nf.string(for: latMinutes) ?? "")\' \(nf.string(for: latSeconds) ?? "")\" \(latDegrees >= 0 ? "N" : "S")"
    }
    
    @objc public static func longitudeDMSString(coordinate: CLLocationDegrees) -> String {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        nf.minimumIntegerDigits = 2

        var lonDegrees: Int = Int(coordinate)
        var lonMinutes = Int(abs((coordinate.truncatingRemainder(dividingBy: 1) * 60.0)))
        var lonSeconds = abs(((coordinate.truncatingRemainder(dividingBy: 1) * 60.0).truncatingRemainder(dividingBy: 1) * 60.0)).rounded()
        if lonSeconds == 60 {
            lonSeconds = 0
            lonMinutes += 1
        }
        if lonMinutes == 60 {
            lonDegrees += 1
            lonMinutes = 0
        }
        return "\(abs(lonDegrees))° \(nf.string(for: lonMinutes) ?? "")\' \(nf.string(for: lonSeconds) ?? "")\" \(lonDegrees >= 0 ? "E" : "W")"
    }
}
