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
    @State private var showingLargeCountWarning = false
    @State private var pendingTimeSelection: TimeFilterEnum?
    @State private var pendingPreviousTimeSelection: TimeFilterEnum = .all
    @State private var pendingObservationCount: Int?
    @State private var lastConfirmedTime: TimeFilterEnum = .all

    private var warningTitle: String {
        "Show Observations?"
    }

    private var warningMessage: String {
        let countText = pendingObservationCount.map { "\($0) observations" } ?? "these observations"
        return "Are you sure you want to show \(countText)? The application may become unresponsive."
    }

    private var confirmButtonTitle: String {
        "Show Observations"
    }

    private func evaluateCustomTimeWarning() {
        guard observationFilterViewModel.selectedTime == .custom else { return }
        guard !showingLargeCountWarning else { return }
        let previousSelection = lastConfirmedTime
        Task {
            let warningCount = await observationFilterViewModel.warningCountForTimeSelection(
                .custom,
                customNumber: observationFilterViewModel.customTimeFieldValue,
                customUnit: observationFilterViewModel.customTimePickerEnum
            )
            await MainActor.run {
                guard observationFilterViewModel.selectedTime == .custom else { return }
                if let warningCount {
                    pendingTimeSelection = .custom
                    pendingPreviousTimeSelection = previousSelection
                    pendingObservationCount = warningCount
                    showingLargeCountWarning = true
                } else {
                    lastConfirmedTime = .custom
                }
            }
        }
    }

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
                                guard observationFilterViewModel.selectedTime != option else { return }
                                if option == .all || option == .custom {
                                    let previousSelection = lastConfirmedTime
                                    observationFilterViewModel.selectedTime = option
                                    Task {
                                        let warningCount = await observationFilterViewModel.warningCountForTimeSelection(
                                            option,
                                            customNumber: observationFilterViewModel.customTimeFieldValue,
                                            customUnit: observationFilterViewModel.customTimePickerEnum
                                        )
                                        await MainActor.run {
                                            guard observationFilterViewModel.selectedTime == option else { return }
                                            if let warningCount {
                                                pendingTimeSelection = option
                                                pendingPreviousTimeSelection = previousSelection
                                                pendingObservationCount = warningCount
                                                showingLargeCountWarning = true
                                            } else {
                                                lastConfirmedTime = option
                                            }
                                        }
                                    }
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
        .onChange(of: observationFilterViewModel.customTimeFieldValue) { _ in
            evaluateCustomTimeWarning()
        }
        .onChange(of: observationFilterViewModel.customTimePickerEnum) { _ in
            evaluateCustomTimeWarning()
        }
        .alert(warningTitle, isPresented: $showingLargeCountWarning) {
            Button(confirmButtonTitle) {
                if let pendingTimeSelection {
                    observationFilterViewModel.selectedTime = pendingTimeSelection
                    lastConfirmedTime = pendingTimeSelection
                }
                pendingTimeSelection = nil
                pendingObservationCount = nil
            }
            Button("Cancel", role: .cancel) {
                observationFilterViewModel.selectedTime = pendingPreviousTimeSelection
                lastConfirmedTime = pendingPreviousTimeSelection
                pendingTimeSelection = nil
                pendingObservationCount = nil
            }
        } message: {
            Text(warningMessage)
        }
    }
}

#Preview {
    ObservationFilterView()
}
