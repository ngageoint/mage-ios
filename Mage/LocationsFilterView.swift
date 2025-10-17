//
//  LocationsFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocationsFilterView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime: TimeFilterEnum = .all
    
    @State var customTimeFieldValue: Int = UserDefaults.standard.observationTimeFilterNumberKey
    @State var customTimePickerEnum: TimeUnitWrapper = TimeUnitWrapper(objcValue: UserDefaults.standard.observationTimeFilterUnitKey)
    
    var body: some View {
        List {
            Section("Time Filter") {
                ForEach(TimeFilterEnum.allCases) { option in
                    TimeFilterView(
                        title: option.title,
                        subTitle: option.subtitle,
                        timeFilter: option,
                        customTimeFieldValue: $customTimeFieldValue,
                        customTimePickerEnum: $customTimePickerEnum,
                        isSelected: Binding(
                            get: { selectedTime == option },
                            set: { newValue in if newValue { selectedTime = option } }
                        )
                    )
                }
            }
        }
        .navigationTitle("Locations Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { loadFromObjC() }
        .onChange(of: selectedTime)  { saveTimeFilter($0); notifyObservationFiltersChanged() }
        .onChange(of: customTimeFieldValue) { saveCustomTimeFieldValueFilter($0)}
        .onChange(of: customTimePickerEnum) { saveCustomTimeEnumFilter($0)}
    }
    
    private func notifyObservationFiltersChanged() {
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }
    
    private func loadFromObjC() {
        selectedTime  = TimeFilterEnum(objc: TimeFilter.getObservationTimeFilter())
    }
    
    private func saveTimeFilter(_ newValue: TimeFilterEnum) {
        if TimeFilter.getObservationTimeFilter() != newValue.objc {
            TimeFilter.setObservation(newValue.objc)
        }
    }
    
    private func saveCustomTimeFieldValueFilter(_ newValue: Int) {
        if TimeFilter.getObservationCustomTimeFilterNumber() != newValue {
            TimeFilter.setObservationCustomTimeFilterNumber(newValue)
        }
    }
    
    private func saveCustomTimeEnumFilter(_ newValue: TimeUnitWrapper) {
        if TimeFilter.getObservationCustomTimeFilterUnit() != newValue.objcValue {
            TimeFilter.setObservationCustomTimeFilterUnit(newValue.objcValue)
        }
    }
    
    private func applyFilterAndDismiss() {
        saveTimeFilter(selectedTime)
        notifyObservationFiltersChanged()
        dismiss()
    }
}

#Preview {
    LocationsFilterView()
}
