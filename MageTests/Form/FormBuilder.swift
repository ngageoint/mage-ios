//
//  FormBuilder.swift
//  MAGE
//
//  Created by Daniel Barela on 5/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MagicalRecord

@testable import MAGE

class FormBuilder {
    
    static func createFormWithAllFieldTypes(eventId: NSNumber = 1) -> Form {
        guard let pathString = Bundle(for: FormBuilder.self).path(forResource: "allFieldTypesForm", ofType: "json") else {
            fatalError("jsonFileName not found")
        }
        
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert pathString to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert jsonFileName to Data")
        }
        
        var form: Form;
        
        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String:Any]
            form = Form.createForm(eventId: eventId, order: 0, formJson: jsonDictionary, context: NSManagedObjectContext.mr_default())!
        } catch {
            fatalError("Unable to convert jsonFileName to JSON dictionary \(error)")
        }
        
        return form;
    }
    
    static func createEmptyForm(eventId: NSNumber = 1) -> Form {
        guard let pathString = Bundle(for: FormBuilder.self).path(forResource: "emptyForm", ofType: "json") else {
            fatalError("jsonFileName not found")
        }
        
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert pathString to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert jsonFileName to Data")
        }
        
        var form: Form;

        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String:Any]
            form = Form.createForm(eventId: eventId, order: 0, formJson: jsonDictionary, context: NSManagedObjectContext.mr_default())!
        } catch {
            fatalError("Unable to convert jsonFileName to JSON dictionary \(error)")
        }
        
        return form;
    }
    
}
