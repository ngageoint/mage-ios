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
    
    var body: some View {
        List {
            Section("Time Filter") {
                ForEach(TimeFilterEnum.allCases) { option in
                    TimeFilterView(
                        title: option.title,
                        subTitle: option.subtitle,
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
    
    private func applyFilterAndDismiss() {
        saveTimeFilter(selectedTime)
        notifyObservationFiltersChanged()
        dismiss()
    }
}

#Preview {
    LocationsFilterView()
}
