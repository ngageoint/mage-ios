//
//  Form.m
//  mage-ios-sdk
//
//

import Foundation
import ZipArchive
import CoreData

import Persistence

extension Form {
    
    @objc public static let MAGEFormFetched = "mil.nga.giat.mage.form.fetched";
    
    @objc public var name: String? {
        get {
            return json?.json?[FormKey.name.key] as? String
        }
    }
    
    @objc public var formDescription: String? {
        get {
            return json?.json?[FormKey.description.key] as? String
        }
    }
    
    @objc public var fields: [[String: AnyHashable]]? {
        get {
            return json?.json?[FormKey.fields.key] as? [[String: AnyHashable]]
        }
    }
    
    public var min: Int? {
        get {
            return json?.json?[FormKey.min.key] as? Int
        }
    }
    
    public var max: Int? {
        get {
            return json?.json?[FormKey.max.key] as? Int
        }
    }
    
    public var isDefault: Bool {
        get {
            return json?.json?[FormKey.isDefault.key] as? Bool ?? false
        }
    }
    
    @objc public var color: String? {
        get {
            return json?.json?[FormKey.color.key] as? String
        }
    }
    
    @objc public var style: [AnyHashable:Any]? {
        get {
            return json?.json?[FormKey.style.key] as? [AnyHashable:Any]
        }
    }
    
    @objc public func getFieldByName(name: String) -> [String: AnyHashable]? {
        if let fields = json?.json?[FormKey.fields.key] as? [[String: AnyHashable]] {
            return fields.first { field in
                field[FieldKey.name.key] as? String == name
            }
        }
        return nil
    }
    
    static func getFieldByNameFromJSONFields(json: [[String: AnyHashable]], name: String) -> [String: AnyHashable]? {
        return json.first { field in
            field[FieldKey.name.key] as? String == name
        }
    }
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
}
