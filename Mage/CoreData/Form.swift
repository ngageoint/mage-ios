//
//  Form.m
//  mage-ios-sdk
//
//

import Foundation
import SSZipArchive
import CoreData

@objc public class Form: NSManagedObject {
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @objc public static let MAGEFormFetched = "mil.nga.giat.mage.form.fetched";
    
    @discardableResult
    @objc public static func deleteAllFormsForEvent(eventId: NSNumber, context: NSManagedObjectContext) -> Bool {
        return context.performAndWait {
            do {
                let forms = try context.fetchObjects(Form.self, predicate: NSPredicate(format: "eventId == %@", eventId))
                for form in forms ?? [] {
                    context.delete(form)
                }
                return true
            } catch {
                NSLog("Could not delete forms \(error)")
                return false
            }
        }
    }
    
    @discardableResult
    @objc public static func createForm(eventId: NSNumber, order: NSNumber, formJson: [AnyHashable : Any], context: NSManagedObjectContext) -> Form? {
        return context.performAndWait {
            if let formId = formJson[FormKey.id.key] as? NSNumber {
                let form = Form(context: context)
                let formJsonEntity = FormJson(context: context)
                formJsonEntity.json = formJson
                formJsonEntity.formId = formId
                form.json = formJsonEntity
                form.eventId = eventId
                form.archived = formJson[FormKey.archived.key] as? Bool ?? false
                form.formId = formId
                form.order = order
                
                if let formFields = formJson[FormKey.fields.key] as? [[AnyHashable: Any]] {
                    if let primaryMapFieldName = formJson[FormKey.primaryField.key] as? String {
                        form.primaryMapField = formFields.first { field in
                            if let fieldName = field[FieldKey.name.key] as? String {
                                return fieldName == primaryMapFieldName
                            }
                            return false
                        }
                    }
                    if let secondaryMapFieldName = formJson[FormKey.secondaryField.key] as? String {
                        form.secondaryMapField = formFields.first { field in
                            if let fieldName = field[FieldKey.name.key] as? String {
                                return fieldName == secondaryMapFieldName
                            }
                            return false
                        }
                    }
                    if let primaryFeedFieldName = formJson[FormKey.primaryFeedField.key] as? String {
                        form.primaryFeedField = formFields.first { field in
                            if let fieldName = field[FieldKey.name.key] as? String {
                                return fieldName == primaryFeedFieldName
                            }
                            return false
                        }
                    }
                    if let secondaryFeedFieldName = formJson[FormKey.secondaryFeedField.key] as? String {
                        form.secondaryFeedField = formFields.first { field in
                            if let fieldName = field[FieldKey.name.key] as? String {
                                return fieldName == secondaryFeedFieldName
                            }
                            return false
                        }
                    }
                }
                try? context.obtainPermanentIDs(for: [form])
                try? context.save()
                return form
            }
            return nil
        }
    }
    
    @discardableResult
    @objc public static func deleteAndRecreateForms(eventId: NSNumber, formsJson:[[AnyHashable: Any]], context: NSManagedObjectContext) -> [Form] {
        
        return context.performAndWait {
            Form.deleteAllFormsForEvent(eventId: eventId, context: context)
            var forms: [Form] = []
            for (index, formJson) in formsJson.enumerated() {
                if let form = Form.createForm(eventId: eventId, order: NSNumber(value: index), formJson: formJson, context: context) {
                    forms.append(form)
                }
            }
            try? context.save()
            return forms
        }
    }
    
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

    @objc public static func operationToPullFormIcons(eventId: NSNumber, success: (() -> Void)?, failure: ((Error) -> Void)?) -> URLSessionDownloadTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(eventId)/form/icons.zip";
        let manager = MageSessionManager.shared();
        
        let stringPath = "\(getDocumentsDirectory())/events/icons-\(eventId).zip"
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-\(eventId)"
        
        do {
            let methodStart = Date()
            NSLog("TIMING Fetching Form for event \(eventId) @ \(methodStart)")

            guard let request = try manager?.requestSerializer.request(withMethod: "GET", urlString: url, parameters: nil) else {
                return nil;
            }
            let task = manager?.downloadTask(with: request as URLRequest, progress: nil, destination: { targetPath, response in
                return URL(fileURLWithPath: stringPath);
            }, completionHandler: { response, filePath, error in
                NSLog("TIMING Fetched Form for event \(eventId). Elapsed: \(methodStart.timeIntervalSinceNow) seconds")

                if let error = error {
                    NSLog("Error pulling icons and form \(error)")
                    failure?(error);
                    return;
                }
                
                NSLog("event form icon request complete")
                guard let fileString = filePath?.path else {
                    return;
                }
                let unzipped = SSZipArchive.unzipFile(atPath: fileString, toDestination: folderToUnzipTo)
                if FileManager.default.isDeletableFile(atPath: fileString) {
                    do {
                        try FileManager.default.removeItem(atPath: fileString)
                    } catch {
                        NSLog("Error removing file at path: %@", error.localizedDescription);
                    }
                }
                if unzipped {
                    success?()
                } else {
                    // TODO: make actual mage errors
                    failure?(NSError(domain: "MAGE", code: 1, userInfo: nil));
                }
            })
            
            if !FileManager.default.fileExists(atPath: stringPath) {
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: stringPath).deletingLastPathComponent(), withIntermediateDirectories: true)
                } catch {
                    NSLog("Error creating directory for icons \(error)")
                }
            }
            
            return task;
        } catch {
            NSLog("Exception creating request \(error)")
        }
        return nil;
    }
}
