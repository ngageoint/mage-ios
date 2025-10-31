//
//  MainFilterViewModel.swift
//  MAGE
//
//  Created by Daniel Benner on 10/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.

import Combine

class MainFilterViewModel: ObservableObject {
    @Published var observationsTime: String = ""
    @Published var locationsTime: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        updateValues()

        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateValues()
            }
            .store(in: &cancellables)
    }

    private func updateValues() {
        let obsFilter = TimeFilter.getObservationTimeFilter()
        observationsTime = label(for: obsFilter)

        let locFilter = TimeFilter.getLocationTimeFilter()
        locationsTime = label(for: locFilter)
    }

    private func label(for filter: TimeFilterType) -> String {
        switch filter {
        case .all: return "All"
        case .today: return "Today"
        case .last24Hours: return "Last 24 Hours"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .custom: return "Custom"
        default: return "None"
        }
    }
}
