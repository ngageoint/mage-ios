//
//  ObservationLocationFieldViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationLocationFieldViewModel: ObservableObject {
    @Injected(\.observationLocationRepository)
    var observationLocationRepository: ObservationLocationRepository
    
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
    var observationFormId: String? {
        didSet {
            Task {
                await getObservationMapItems()
            }
        }
    }
    var fieldName: String? {
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
        guard let observationUri = observationUri, let observationFormId = observationFormId, let fieldName = fieldName else {
            return
        }
        if let observationMapItems = await observationLocationRepository.getObservationMapItems(
            observationUri: observationUri,
            formId: observationFormId,
            fieldName: fieldName
        ) {
            await MainActor.run {
                self.observationMapItems = observationMapItems
            }
        }
    }
}
