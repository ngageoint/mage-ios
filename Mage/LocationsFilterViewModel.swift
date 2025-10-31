//
//  LocationsFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

class LocationsFilterViewModel: ObservableObject {
    
    @Published var selectedTime: TimeFilterEnum = .all
    @Published var customTimeFieldValue: Int = UserDefaults.standard.locationTimeFilterNumber
    @Published var customTimePickerEnum: TimeUnitWrapper = TimeUnitWrapper(objcValue: UserDefaults.standard.locationTimeFilterUnit)
    
    func loadFromObjC() {
        selectedTime  = TimeFilterEnum(objc: TimeFilter.getLocationTimeFilter())
    }

    func saveTimeFilter(_ newValue: TimeFilterEnum) {
        if TimeFilter.getLocationTimeFilter() != newValue.objc {
            TimeFilter.setLocation(newValue.objc)
        }
    }
    
    func saveCustomTimeFieldValueFilter(_ newValue: Int) {
        if TimeFilter.getLocationCustomTimeFilterNumber() != newValue {
            TimeFilter.setLocationCustomTimeFilterNumber(newValue)
        }
    }
    
    func saveCustomTimeEnumFilter(_ newValue: TimeUnitWrapper) {
        if TimeFilter.getLocationCustomTimeFilterUnit() != newValue.objcValue {
            TimeFilter.setLocationCustomTimeFilterUnit(newValue.objcValue)
        }
    }

    func applyFilter() {
        saveTimeFilter(selectedTime)
    }
}
