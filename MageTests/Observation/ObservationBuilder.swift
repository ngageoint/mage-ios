//
//  ObservationBuilder.swift
//  MAGE
//
//  Created by Daniel Barela on 5/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class ObservationBuilder {
    static func createBaseObservation(_ eventId: NSNumber = 1) -> Observation {
        let observation: Observation = Observation(context: NSManagedObjectContext.mr_default());
        observation.eventId = eventId;
        return observation
    }
    
    static func createObservation(jsonFileName: String, eventId: NSNumber = 1) -> Observation {
        guard let pathString = Bundle(for: ObservationBuilder.self).path(forResource: jsonFileName, ofType: "json") else {
            fatalError("jsonFileName not found")
        }

        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert pathString to String")
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert jsonFileName to Data")
        }

        var jsonDictionaryObservation: [String:Any] = [:];

        do {
            jsonDictionaryObservation = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String:Any]
        } catch _ as NSError {
            fatalError("Unable to convert jsonFileName to JSON dictionary")
        }
        
        let observation = createBaseObservation(eventId);
        observation.populateObject(fromJson: jsonDictionaryObservation);
        return observation;
    }
    
    static func createGeometryObservation(eventId: NSNumber = 1, jsonFileName: String?, geometry: SFGeometry) -> Observation {
        var observation: Observation;
        observation = createBaseObservation(eventId);
        if (jsonFileName != nil) {
            observation = createObservation(jsonFileName: jsonFileName!, eventId: eventId);
        }
        observation.setGeometry(geometry);
        return observation;
    }
    
    static func createPointObservation(eventId: NSNumber = 1, jsonFileName: String? = nil) -> Observation {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        return createGeometryObservation(jsonFileName: jsonFileName, geometry: point);
    }
    
    static func createLineObservation(eventId: NSNumber = 1, jsonFileName: String? = nil) -> Observation {
        let points: NSMutableArray = [SFPoint(x: -105.2678, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0085) as Any]
        
        let line: SFLineString = SFLineString(points: points);
        return createGeometryObservation(jsonFileName: jsonFileName, geometry: line);
    }
    
    static func createPolygonObservation(eventId: NSNumber = 1, jsonFileName: String? = nil) -> Observation {
        let points: NSMutableArray = [SFPoint(x: -105.2678, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0102) as Any, SFPoint(x: -105.2678, andY: 40.0102) as Any]
        let line: SFLineString = SFLineString(points: points);
        let poly: SFPolygon = SFPolygon(ring: line);
        return createGeometryObservation(jsonFileName: jsonFileName, geometry: poly);
    }
}
