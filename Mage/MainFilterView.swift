//
//  MainFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct MainFilterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: MainFilterViewModel = MainFilterViewModel()

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ObservationFilterView()) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Observations")
                                .font(.body)
                            Text(viewModel.observationsTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink(destination: LocationsFilterView()) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Locations")
                                .font(.body)
                            Text(viewModel.locationsTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}


#Preview {
    MainFilterView()
}
