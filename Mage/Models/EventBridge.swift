//
//  EventBridge.swift
//  MAGE
//
//  Created by Brent Michalski on 10/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import CoreData

@objc public final class EventBridge: NSObject {
    @objc public static func fetchEvents() {
        let hasBase = (MageServer.baseURL() != nil)
        @Injected(\.nsManagedObjectContext) var ctx: NSManagedObjectContext?
        print("FetchEvents preflight → baseURL:\(hasBase) ctx:\(String(describing: ctx))")

        guard let task = Event.operationToFetchEvents(
            success: { _, _ in print("== FetchEvents Success ==") },
            failure: { _, err in print("== FetchEvents Failure: \(err)") }
        ) else {
            print("Event.operationToFetchEvents returned nil (missing baseURL or context).")
            return
        }
        
        MageSessionManager.shared()?.addTask(task)
    }
}
