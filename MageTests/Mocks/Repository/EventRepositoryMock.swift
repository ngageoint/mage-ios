//
//  EventRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class EventRepositoryMock: EventRepository {
    func getEvents() -> [MAGE.EventModel] {
        events
    }
    
    var fetchEventsCalled = false
    func fetchEvents() async {
        fetchEventsCalled = true
    }
    
    var events: [EventModel] = []
    
    func getEvent(eventId: NSNumber) -> EventModel? {
        events.first { event in
            event.remoteId == eventId
        }
    }
}
