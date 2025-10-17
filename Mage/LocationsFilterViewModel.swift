//
//  LocationsFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

class LocationsFilterViewModel: ObservableObject {
    
    @Published var isFavoriteOn: Bool = false
    @Published var isImportantOn: Bool = false
    @Published var selectedTime: TimeFilterEnum = .all
    @Published var customTimeFieldValue: Int = UserDefaults.standard.observationTimeFilterNumberKey
    @Published var customTimePickerEnum: TimeUnitWrapper = TimeUnitWrapper(objcValue: UserDefaults.standard.observationTimeFilterUnitKey)
    
    func loadFromObjC() {
        isFavoriteOn  = Observations.getFavoritesFilter()
        isImportantOn = Observations.getImportantFilter()
        selectedTime  = TimeFilterEnum(objc: TimeFilter.getObservationTimeFilter())
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
    }
}
