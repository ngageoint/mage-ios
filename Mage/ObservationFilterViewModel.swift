//
//  ObservationFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

class ObservationFilterViewModel: ObservableObject {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Published var isFavoriteOn: Bool = false
    @Published var isImportantOn: Bool = false
    @Published var selectedTime: TimeFilterEnum = .all
    @Published var customTimeFieldValue: Int = UserDefaults.standard.observationTimeFilterNumberKey
    @Published var customTimePickerEnum: TimeUnitWrapper = TimeUnitWrapper(objcValue: UserDefaults.standard.observationTimeFilterUnitKey)
    @Published var selectedUserCount: Int = 0
    
    private let ALERT_THRESHOLD = 5000
    private var defaultsObserver: NSObjectProtocol?
    
    init() {
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSelectedUserCount()
        }
    }
    
    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }
    
    private func refreshSelectedUserCount() {
        selectedUserCount = UserDefaults.standard.userFilterRemoteIds?.count ?? 0
    }
    
    func update() {
        refreshSelectedUserCount()
        isFavoriteOn  = Observations.getFavoritesFilter()
        isImportantOn = Observations.getImportantFilter()
        selectedTime  = TimeFilterEnum(objc: TimeFilter.getObservationTimeFilter())
        customTimeFieldValue = UserDefaults.standard.observationTimeFilterNumberKey
        customTimePickerEnum = TimeUnitWrapper(objcValue: UserDefaults.standard.observationTimeFilterUnitKey)
    }

    func saveFavorites(_ newValue: Bool) {
        if Observations.getFavoritesFilter() != newValue {
            Observations.setFavoritesFilter(newValue)
        }
    }

    func saveImportant(_ newValue: Bool) {
        if Observations.getImportantFilter() != newValue {
            Observations.setImportantFilter(newValue)
        }
    }

    func saveTimeFilter(_ newValue: TimeFilterEnum) {
        if TimeFilter.getObservationTimeFilter() != newValue.objc {
            TimeFilter.setObservation(newValue.objc)
        }
    }
    
    func saveCustomTimeFieldValueFilter(_ newValue: Int) {
        if TimeFilter.getObservationCustomTimeFilterNumber() != newValue {
            TimeFilter.setObservationCustomTimeFilterNumber(newValue)
        }
    }
    
    func saveCustomTimeEnumFilter(_ newValue: TimeUnitWrapper) {
        if TimeFilter.getObservationCustomTimeFilterUnit() != newValue.objcValue {
            TimeFilter.setObservationCustomTimeFilterUnit(newValue.objcValue)
        }
    }

    func applyFilter() {
        saveTimeFilter(selectedTime)
        saveImportant(isImportantOn)
        saveFavorites(isFavoriteOn)
        saveCustomTimeFieldValueFilter(customTimeFieldValue)
        saveCustomTimeEnumFilter(customTimePickerEnum)
    }

    func warningCountForTimeSelection(
        _ timeFilter: TimeFilterEnum,
        customNumber: Int,
        customUnit: TimeUnitWrapper
    ) async -> Int? {
        guard timeFilter == .all || timeFilter == .custom else { return nil }
        let count = await observationRepository.count(
            timeFilter: timeFilter.objc,
            customNumber: customNumber,
            customUnit: customUnit.objcValue
        )
        return count > ALERT_THRESHOLD ? count : nil
    }
}
