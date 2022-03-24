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

public class LocationUtilities: NSObject {
    
    override public init() { }

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
        // remove all characers except numbers and decimal points
        charactersToKeep = CharacterSet()
        charactersToKeep.formUnion(.decimalDigits)
        charactersToKeep.insert(charactersIn: ".")
        coordinateToParse = coordinate.components(separatedBy: charactersToKeep.inverted).joined()
        
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
