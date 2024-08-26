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
    func getEvent(eventId: NSNumber) -> EventModel?
    
}

class EventCoreDataDataSource: CoreDataDataSource<Event>, EventLocalDataSource, ObservableObject {
    
    func getEvent(eventId: NSNumber) -> EventModel? {
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            if let event = Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: eventId, in: context) {
                return EventModel(event: event)
            }
            return nil
        }
    }
}
