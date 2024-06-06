//
//  ObservationRemoteDataSource.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import BackgroundTasks

private struct ObservationRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationRemoteDataSource = ObservationRemoteDataSource()
}

extension InjectedValues {
    var observationRemoteDataSource: ObservationRemoteDataSource {
        get { Self[ObservationRemoteDataSourceProviderKey.self] }
        set { Self[ObservationRemoteDataSourceProviderKey.self] = newValue }
    }
}

class ObservationRemoteDataSource: RemoteDataSource<[AnyHashable : Any]> {
    init(cleanup: (() -> Void)? = nil) {
        super.init(dataSource: DataSources.observation, cleanup: cleanup)
    }

    func fetch(task: BGTask? = nil, eventId: Int, date: Date? = nil) async -> [[AnyHashable : Any]] {
        let operation = ObservationDataFetchOperation(eventId: eventId, date: date)
        return await fetch(task: task, operation: operation)
    }
}
