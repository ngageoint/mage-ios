//
//  EventRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct EventRepositoryProviderKey: InjectionKey {
    static var currentValue: EventRepository = EventRepositoryImpl()
}

extension InjectedValues {
    var eventRepository: EventRepository {
        get { Self[EventRepositoryProviderKey.self] }
        set { Self[EventRepositoryProviderKey.self] = newValue }
    }
}

protocol EventRepository {
    func getEvent(eventId: NSNumber) -> EventModel?
    func fetchEvents() async
}

class EventRepositoryImpl: ObservableObject, EventRepository {
    @Injected(\.eventLocalDataSource)
    var localDataSource: EventLocalDataSource
    
    @Injected(\.eventRemoteDataSource)
    var remoteDataSource: EventRemoteDataSource
    
    func getEvent(eventId: NSNumber) -> EventModel? {
        localDataSource.getEvent(eventId: eventId)
    }
    
    func fetchEvents() async {
        if let response = await remoteDataSource.fetchEvents() {
            await localDataSource.handleEventsResponse(response: response)
        }
    }
}
