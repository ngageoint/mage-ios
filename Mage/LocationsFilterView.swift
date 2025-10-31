//
//  LocationsFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocationsFilterView: View {
    @StateObject private var locationsFilterViewModel = LocationsFilterViewModel()
    
    var body: some View {
        List {
            Section("Time Filter") {
                ForEach(TimeFilterEnum.allCases) { option in
                    TimeFilterView(
                        title: option.title,
                        subTitle: option.subtitle,
                        timeFilter: option,
                        customTimeFieldValue: $locationsFilterViewModel.customTimeFieldValue,
                        customTimePickerEnum: $locationsFilterViewModel.customTimePickerEnum,
                        isSelected: Binding(
                            get: { locationsFilterViewModel.selectedTime == option },
                            set: { if $0 { locationsFilterViewModel.selectedTime = option } }
                        )
                    )
                }
            }
        }
        .navigationTitle("Locations Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { locationsFilterViewModel.loadFromObjC() }
        .onChange(of: locationsFilterViewModel.selectedTime)  { locationsFilterViewModel.saveTimeFilter($0) }
        .onChange(of: locationsFilterViewModel.customTimeFieldValue) { locationsFilterViewModel.saveCustomTimeFieldValueFilter($0)}
        .onChange(of: locationsFilterViewModel.customTimePickerEnum) { locationsFilterViewModel.saveCustomTimeEnumFilter($0)}
    }
}

#Preview {
    LocationsFilterView()
}
