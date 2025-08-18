//
//  FilterView.swift
//  MAGE
//
//  Created by James McDougall on 8/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    
    let filters = [
        FilterModel(name: "Observations", subtitle: "Last Month"),
        FilterModel(name: "Locations", subtitle: "Last Month"),
        FilterModel(name: "Users", subtitle: "Last Month"),
    ]
    
    var body: some View {
        NavigationStack {
            List(filters) { item in
                NavigationLink {
                    
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.title3)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            }
            .listStyle(.grouped)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    FilterView()
}
