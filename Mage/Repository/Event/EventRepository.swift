//
//  EventRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct EventRepositoryProviderKey: InjectionKey {
    static var currentValue: EventRepository = EventRepository()
}

extension InjectedValues {
    var eventRepository: EventRepository {
        get { Self[EventRepositoryProviderKey.self] }
        set { Self[EventRepositoryProviderKey.self] = newValue }
    }
}

class EventRepository: ObservableObject {
    @Injected(\.eventLocalDataSource)
    var localDataSource: EventLocalDataSource
    
    func getEvent(eventId: NSNumber) -> Event? {
        localDataSource.getEvent(eventId: eventId)
    }
}
