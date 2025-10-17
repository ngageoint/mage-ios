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

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ObservationFilterView()) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Observations")
                            Text("Last Month")
                                .font(.body2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                NavigationLink(destination: LocationsFilterView()) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Locations")
                            Text("Last Month")
                                .font(.body2)
                                .foregroundStyle(.gray)
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
