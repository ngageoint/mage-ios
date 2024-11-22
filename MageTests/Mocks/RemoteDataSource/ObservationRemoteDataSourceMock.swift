//
//  ObservationRemoteDataSourceMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import BackgroundTasks

@testable import MAGE

class ObservationRemoteDataSourceMock: ObservationRemoteDataSource {
    var fetchDate: Date?
    var fetchEvent: Int?
    var fetchResponseToSend: [[AnyHashable: Any]] = [[:]]
    
    override func fetch(task: BGTask? = nil, eventId: Int, date: Date? = nil) async -> [[AnyHashable : Any]] {
        fetchDate = date
        fetchEvent = eventId
        return fetchResponseToSend
    }
}
