//
//  ObservationMapItemViewModel.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationMapItemViewModel: ObservableObject {
    var repository: ObservationRepository? {
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
    @Published var selectedItem: Int = 0

    var currentItem: ObservationMapItem? {
        if selectedItem < observationMapItems.count {
            return observationMapItems[selectedItem]
        }
        return nil
    }

    func getObservationMapItems() async {
        guard let repository = repository, let observationUri = observationUri else {
            return
        }
        let fetched = await repository.getMapItems(observationUri: observationUri)
        await MainActor.run {
            self.observationMapItems = fetched
        }
    }
}
