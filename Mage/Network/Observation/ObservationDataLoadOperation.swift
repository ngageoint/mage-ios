//
//  ObservationDataLoadOperation.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
class ObservationDataLoadOperation: CountingDataLoadOperation {

    var observations: [[AnyHashable: Any]] = []
    var localDataSource: ObservationLocalDataSource
    var eventId: Int

    init(observations: [[AnyHashable: Any]], localDataSource: ObservationLocalDataSource, eventId: Int) {
        self.observations = observations
        self.localDataSource = localDataSource
        self.eventId = eventId
    }

    @MainActor override func finishLoad() {
        self.state = .isFinished
    }

    override func loadData() async {
        if self.isCancelled {
            return
        }

        count = (try? await localDataSource.batchImport(from: observations, eventId: eventId)) ?? 0
    }
}
