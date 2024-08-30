//
//  ObservationBuilder.swift
//  MAGE
//
//  Created by Daniel Barela on 5/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MagicalRecord

@testable import MAGE

class ObservationBuilder {
    static func createBlankObservation(_ eventId: NSNumber = 0, context: NSManagedObjectContext? = nil) -> Observation {
        var observation: Observation!;
        if let safeContext = context {
            observation = Observation(context: safeContext)
        } else {
            fatalError()
        }
        observation.eventId = eventId;
        let observationProperties: [String:Any] = [:]
        observation.properties = observationProperties;
        return observation
    }
    
    static func createObservation(jsonFileName: String, eventId: NSNumber = 0, context: NSManagedObjectContext? = nil) -> Observation {
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
        
        let observation = createBlankObservation(eventId, context: context);
        observation.populate(json: jsonDictionaryObservation);
        return observation;
    }
    
    static func createGeometryObservation(eventId: NSNumber = 0, jsonFileName: String?, geometry: SFGeometry, context: NSManagedObjectContext? = nil) -> Observation {
        var observation: Observation;
        observation = createBlankObservation(eventId, context: context);
        if (jsonFileName != nil) {
            observation = createObservation(jsonFileName: jsonFileName!, eventId: eventId, context: context);
        }
        observation.geometry = geometry;
        return observation;
    }
    
    static func createPointObservation(eventId: NSNumber = 0, jsonFileName: String? = nil, context: NSManagedObjectContext? = nil) -> Observation {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        return createGeometryObservation(eventId: eventId, jsonFileName: jsonFileName, geometry: point, context: context);
    }
    
    static func createLineObservation(eventId: NSNumber = 0, jsonFileName: String? = nil, context: NSManagedObjectContext? = nil) -> Observation {
        let points: NSMutableArray = [SFPoint(x: -105.2678, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0085) as Any]
        
        let line: SFLineString = SFLineString(points: points);
        return createGeometryObservation(eventId: eventId, jsonFileName: jsonFileName, geometry: line, context: context);
    }
    
    static func createPolygonObservation(eventId: NSNumber = 0, jsonFileName: String? = nil, context: NSManagedObjectContext? = nil) -> Observation {
        let points: NSMutableArray = [SFPoint(x: -105.2678, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0085) as Any, SFPoint(x: -105.2653, andY: 40.0102) as Any, SFPoint(x: -105.2678, andY: 40.0102) as Any]
        let line: SFLineString = SFLineString(points: points);
        let poly: SFPolygon = SFPolygon(ring: line);
        return createGeometryObservation(eventId: eventId, jsonFileName: jsonFileName, geometry: poly, context: context);
    }
    
    static func addObservationProperty(observation: Observation, key: String, value: Any) {
        var observationProperties: [String:Any];
        if (observation.properties == nil) {
            observationProperties = [:]
        } else {
            observationProperties = observation.properties as! [String : Any];
        }
        
        observationProperties.updateValue(value, forKey: key);
        observation.properties = observationProperties;
    }
    
    static func setObservationDate(observation: Observation, date: Date) {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        ObservationBuilder.addObservationProperty(observation: observation, key: "timestamp", value: formatter.string(from: date));
        observation.timestamp = date;
    }
    
    static func createAttachment(eventId: NSNumber, name: String? = nil, remoteId: String? = nil, observationRemoteId: String? = nil) -> Attachment {
        let attachment: Attachment = Attachment(context: NSManagedObjectContext.mr_default());
        attachment.localPath = "";
        attachment.name = name;
        attachment.dirty = false;
        attachment.eventId = eventId;
        attachment.contentType = "image/png";
        attachment.observationRemoteId = observationRemoteId;
        attachment.remoteId = remoteId;
        if (observationRemoteId != nil && remoteId != nil) {
            attachment.url = "https://magetest/observation/\(observationRemoteId ?? "")/attachments/remoteid\(remoteId ?? "")";
        }
        attachment.lastModified = Date()
        return attachment;
    }
    
    static func addAttachmentToObservation(observation: Observation) -> Attachment{
        let attachment: Attachment = createAttachment(eventId: observation.eventId!, name: "name\(observation.attachments?.count ?? 0)", remoteId: "remoteid\(observation.attachments?.count ?? 0)", observationRemoteId: observation.remoteId);
        
        observation.addToAttachments(attachment);
        return attachment;
    }
    
    static func addFormToObservation(observation: Observation, form: Form, values: [String: Any?]? = nil) {
        var newProperties: [String: Any] = observation.properties as? [String: Any] ?? [:];
        var observationForms: [Any] = newProperties["forms"] as? [Any] ?? [];
        
        var newForm: [String: Any] = ["formId": form.formId!];
        let defaults: FormDefaults = FormDefaults(eventId: observation.eventId as! Int, formId: form.formId as! Int);
        let formDefaults: [String: [String: Any]] = defaults.getDefaults() as! [String : [String: Any]];
        
        let fields: [[String : Any?]] = form.json!.json!["fields"] as! [[String : Any]];
        if (formDefaults.count > 0) { // user defaults
            for (_, field) in fields.enumerated() {
                var value: Any? = nil;
                if let defaultField: [String:Any] = formDefaults[field["id"] as! String] {
                    value = defaultField
                }
                // override with the values set
                if let safeValues = values {
                    if ((safeValues.keys.contains(field["name"] as! Dictionary<String, Any>.Keys.Element))) {
                        if let safeValue: String = safeValues[field["name"] as! String] as? String {
                            value = safeValue;
                        } else {
                            value = nil;
                        }
                    }
                }
                
//                if (value != nil) {
                    newForm[field["name"] as! String] = value;
//                }
            }
        } else { // server defaults
            for (_, field) in fields.enumerated() {
                var value: Any? = nil;
                // grab the server default from the form fields value property
                if let defaultField: Any = field["value"] as Any? {
                    value = defaultField;
                }
                
                // override with the values set
                if let safeValues = values {
//                    print("\(safeValues.keys)")
//                    print("\(field)")
                    if ((safeValues.keys.contains(field["name"] as! Dictionary<String, Any>.Keys.Element))) {
                        value = safeValues[field["name"] as! String] as Any?;
                    }
                }
                
                if (value != nil) {
                    newForm[field["name"] as! String] = value;
                }
            }
        }
        
        observationForms.append(newForm);
        newProperties["forms"] = observationForms;
        observation.properties = newProperties;
    }
}
