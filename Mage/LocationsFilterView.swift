//
//  LocationsFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocationsFilterView: View {
    
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
    }
}

#Preview {
    LocationsFilterView()
}
