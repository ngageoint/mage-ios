//
//  EventLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct EventLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: EventLocalDataSource = EventCoreDataDataSource()
}

extension InjectedValues {
    var eventLocalDataSource: EventLocalDataSource {
        get { Self[EventLocalDataSourceProviderKey.self] }
        set { Self[EventLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol EventLocalDataSource {
    func getEvent(eventId: NSNumber) -> Event?
    
}

class EventCoreDataDataSource: CoreDataDataSource, EventLocalDataSource, ObservableObject {
    
    func getEvent(eventId: NSNumber) -> Event? {
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            return Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: eventId, in: context)
        }
    }
}
