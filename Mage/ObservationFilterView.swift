//
//  ObservationFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ObservationFilterView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isFavoriteOn  = false
    @State private var isImportantOn = false
    @State private var selectedTime: TimeFilterEnum = .all
    
    

    var body: some View {
        List {
            Section("Filter Types") {
                HStack {
                    Spacer()
                    Toggle(isOn: $isFavoriteOn) {
                        VStack(alignment: .leading) {
                            Text("Favorites")
                            Text("Only show my favorite observations")
                                .font(.body2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Toggle(isOn: $isImportantOn) {
                        VStack(alignment: .leading) {
                            Text("Important")
                            Text("Only show observations flagged as important")
                                .font(.body2)
                                .foregroundStyle(.gray)
                        }
                    }
                }

                NavigationLink(destination: UserObservationFilterView()) {
                    VStack(alignment: .leading) {
                        Text("User Filter")
                        Text("Only show selected users observations")
                            .font(.body2)
                            .foregroundStyle(.gray)
                    }
                    .padding(.leading, 8)
                }
            }

            Section("Time Filter") {
                ForEach(TimeFilterEnum.allCases) { option in
                    TimeFilterView(
                        title: option.title,
                        subTitle: option.subtitle,
                        isSelected: Binding(
                            get: { selectedTime == option },
                            set: { if $0 { selectedTime = option } }
                        )
                    )
                }
            }
        }
        .navigationTitle("Observation Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { loadFromObjC() }
        .onChange(of: isFavoriteOn)  { saveFavorites($0) }
        .onChange(of: isImportantOn) { saveImportant($0) }
        .onChange(of: selectedTime)  { saveTimeFilter($0) }
    }

    private func loadFromObjC() {
        isFavoriteOn  = Observations.getFavoritesFilter()
        isImportantOn = Observations.getImportantFilter()
        selectedTime  = TimeFilterEnum(objc: TimeFilter.getObservationTimeFilter())
    }

    private func saveFavorites(_ newValue: Bool) {
        if Observations.getFavoritesFilter() != newValue {
            Observations.setFavoritesFilter(newValue)
        }
    }

    private func saveImportant(_ newValue: Bool) {
        if Observations.getImportantFilter() != newValue {
            Observations.setImportantFilter(newValue)
        }
    }

    private func saveTimeFilter(_ newValue: TimeFilterEnum) {
        if TimeFilter.getObservationTimeFilter() != newValue.objc {
            TimeFilter.setObservation(newValue.objc)
        }
    }

    // This is for a future method this
    private func notifyObservationFiltersChanged() {
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }

    private func applyFilterAndDismiss() {
        saveTimeFilter(selectedTime)
        saveImportant(isImportantOn)
        saveFavorites(isFavoriteOn)
        notifyObservationFiltersChanged()
        dismiss()
    }
}

#Preview {
    ObservationFilterView()
}
