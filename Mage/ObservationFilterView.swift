//
//  ObservationFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ObservationFilterView: View {
    @StateObject var observationFilterViewModel = ObservationFilterViewModel()

    var body: some View {
        List {
            Section("Filter Types") {
                HStack {
                    Spacer()
                    Toggle(isOn: $observationFilterViewModel.isFavoriteOn) {
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
                    Toggle(isOn: $observationFilterViewModel.isImportantOn) {
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
                        timeFilter: option,
                        customTimeFieldValue: $observationFilterViewModel.customTimeFieldValue,
                        customTimePickerEnum: $observationFilterViewModel.customTimePickerEnum,
                        isSelected: Binding(
                            get: { observationFilterViewModel.selectedTime == option },
                            set: { if $0 { observationFilterViewModel.selectedTime = option } }
                        )
                    )
                }
            }
        }
        .navigationTitle("Observation Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { observationFilterViewModel.loadFromObjC() }
        .onChange(of: observationFilterViewModel.isFavoriteOn)  { observationFilterViewModel.saveFavorites($0) }
        .onChange(of: observationFilterViewModel.isImportantOn) { observationFilterViewModel.saveImportant($0) }
        .onChange(of: observationFilterViewModel.selectedTime)  { observationFilterViewModel.saveTimeFilter($0) }
        .onChange(of: observationFilterViewModel.customTimeFieldValue) { observationFilterViewModel.saveCustomTimeFieldValueFilter($0)}
        .onChange(of: observationFilterViewModel.customTimePickerEnum) { observationFilterViewModel.saveCustomTimeEnumFilter($0)}
    }
}

//#Preview {
//    ObservationFilterView()
//}
