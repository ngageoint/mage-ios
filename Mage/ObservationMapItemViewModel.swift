//
//  ObservationMapItemViewModel.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationMapItemViewModel: ObservableObject {
    @Injected(\.observationMapItemRepository)
    var repository: ObservationMapItemRepository {
        didSet {
            Task {
                await getObservationMapItems()
            }
        }
    }
    @Published var observationUri: URL? {
        didSet {
            Task {
                await getObservationMapItems()
            }
        }
    }
    @Published var observationMapItems: [ObservationMapItem] = []
    @Published var currentItemIndex: Int = 0

    var currentItem: ObservationMapItem? {
        if currentItemIndex < observationMapItems.count {
            return observationMapItems[currentItemIndex]
        }
        return nil
    }

    func getObservationMapItems() async {
        guard let observationUri = observationUri else {
            return
        }
        let fetched = await repository.getMapItems(observationUri: observationUri)
        await MainActor.run {
            self.observationMapItems = fetched
        }
    }
}
