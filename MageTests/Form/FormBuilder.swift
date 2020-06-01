//
//  FormBuilder.swift
//  MAGE
//
//  Created by Daniel Barela on 5/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class FormBuilder {
    
    static func createFormWithAllFieldTypes() -> [String:Any] {
        guard let pathString = Bundle(for: FormBuilder.self).path(forResource: "allFieldTypesForm", ofType: "json") else {
            fatalError("jsonFileName not found")
        }
        
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert pathString to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert jsonFileName to Data")
        }
        
        var jsonDictionary: [String:Any] = [:];
        
        do {
            jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String:Any]
        } catch {
            fatalError("Unable to convert jsonFileName to JSON dictionary \(error)")
        }
        return jsonDictionary;
    }
    
    static func createEmptyForm() -> [String:Any] {
        guard let pathString = Bundle(for: FormBuilder.self).path(forResource: "emptyForm", ofType: "json") else {
            fatalError("jsonFileName not found")
        }
        
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert pathString to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert jsonFileName to Data")
        }
        
        var jsonDictionary: [String:Any] = [:];
        
        do {
            jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String:Any]
        } catch {
            fatalError("Unable to convert jsonFileName to JSON dictionary \(error)")
        }
        return jsonDictionary;
    }
    
}
