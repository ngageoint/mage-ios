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
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return Server.getPropertyForKey(key: "serverUrl", context: context) as? String
    }
    
    @objc public static func setServerUrl(serverUrl: String) {
        Server.setProperty(property: serverUrl, key: "serverUrl")
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
        if let server = try? context.fetchFirst(Server.self), let properties = server.properties {
            return properties[key];
        }
        return nil;
    }
    
    static func setProperty(property: Any, key: String) {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }
        context.performAndWait({
            if let server = try? context.fetchFirst(Server.self) {
                var properties = server.properties ?? [:];
                properties[key] = property
                server.properties = properties;
            } else {
                let server = Server(context: context)
                server.properties = [
                    key: property
                ]
                try? context.obtainPermanentIDs(for: [server])
            }

        })
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
