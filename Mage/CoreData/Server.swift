//
//  Server.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc public class Server: NSManagedObject {
    
    @objc public static func serverUrl() -> String? {
        return Server.getPropertyForKey(key: "serverUrl", context: NSManagedObjectContext.mr_default()) as? String
    }
    
    @objc public static func setServerUrl(serverUrl: String, completion: MRSaveCompletionHandler? = nil) {
        Server.setProperty(property: serverUrl, key: "serverUrl", completion: completion)
    }
    
    @objc public static func currentEventId() -> NSNumber? {
        return UserDefaults.standard.currentEventId as? NSNumber
    }
    
    @objc public static func setCurrentEventId(_ eventId: NSNumber) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.raiseEventTaskPriorities(eventId: eventId);
        }
        
        UserDefaults.standard.currentEventId = eventId;
    }
    
    @objc public static func removeCurrentEventId() {
        UserDefaults.standard.currentEventId = nil;
    }
    
    static func getPropertyForKey(key: String, context: NSManagedObjectContext) -> Any? {
        if let server = Server.mr_findFirst(in: context), let properties = server.properties {
            return properties[key];
        }
        return nil;
    }
    
    static func setProperty(property: Any, key: String, completion: MRSaveCompletionHandler? = nil) {
        MagicalRecord.save({ localContext in
            if let server = Server.mr_findFirst(in: localContext) {
                var properties = server.properties ?? [:];
                properties[key] = property
                server.properties = properties;
            } else if let server = Server.mr_createEntity(in: localContext) {
                server.properties = [
                    key: property
                ]
            }
        }, completion: completion);
    }
    
    static func raiseEventTaskPriorities(eventId: NSNumber) {
        if let eventTasks = MageSessionManager.eventTasks() {
            let manager = MageSessionManager.shared();
            
            if let tasks = eventTasks[eventId] {
                for taskIdentifier in tasks {
                    manager?.readdTask(withIdentifier: UInt(truncating: taskIdentifier), withPriority: URLSessionTask.highPriority);
                }
            }
        }
    }
}
