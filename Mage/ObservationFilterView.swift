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
    @State private var showingUserFilter = false
    @State private var showingAllTimeConfirmation = false
    @State private var lastConfirmedTime: TimeFilterEnum = .all

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
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button {
                    showingUserFilter = true
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("User Filter")
                            Text("Only show selected users’ observations")
                                .font(.body2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()

                        if observationFilterViewModel.selectedUserCount > 0 {
                            Text("\(observationFilterViewModel.selectedUserCount)")
                        }
                        Image(systemName: "chevron.right")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                            set: { isSelected in
                                guard isSelected else { return }
                                if option == .all && observationFilterViewModel.selectedTime != .all {
                                    showingAllTimeConfirmation = true
                                    return
                                }
                                observationFilterViewModel.selectedTime = option
                                lastConfirmedTime = option
                            }
                        )
                    )
                }
            }
        }
        .navigationTitle("Observation Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingUserFilter) {
            UserObservationFilterView()
        }
        .onAppear {
            observationFilterViewModel.update()
            lastConfirmedTime = observationFilterViewModel.selectedTime
        }
        .onDisappear {
            observationFilterViewModel.applyFilter()
        }
        .alert("Show all observations?", isPresented: $showingAllTimeConfirmation) {
            Button("Show All") {
                observationFilterViewModel.selectedTime = .all
                lastConfirmedTime = .all
            }
            Button("Cancel", role: .cancel) {
                observationFilterViewModel.selectedTime = lastConfirmedTime
            }
        } message: {
            Text("Loading 5,000+ observations may cause the application to become unresponsive and lag.")
        }
    }
}

#Preview {
    ObservationFilterView()
}
