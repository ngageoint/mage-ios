//
//  ObservationListRow.swift
//  MAGE
//
//  Created by Brent Michalski on 7/1/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import SwiftUI

struct ObservationListRow: View {
    let uriItem: URIItem
    let viewModel: ObservationsViewModel

    var body: some View {
        switch uriItem {
        case .listItem(let uri):
            ObservationSummaryViewSwiftUI(
                viewModel: ObservationListViewModel(uri: uri)
            )
            .onAppear {
                if viewModel.state.rows.first == uriItem {
                    viewModel.setFirstRowVisible(visible: true)
                }
                if viewModel.state.rows.last == uriItem {
                    viewModel.loadMore()
                }
            }
            .onDisappear {
                if viewModel.state.rows.first == uriItem {
                    viewModel.setFirstRowVisible(visible: false)
                }
            }
        case .sectionHeader:
            EmptyView()
        }
    }
}
