//
//  LocalOnlyLoginSection.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

// MARK: - Local-only layout
struct LocalOnlyLoginSection: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let local = viewModel.strategies.first {
                StrategyRow(strategy: local, user: viewModel.user, delegate: viewModel.delegate)
            }
        }
        .frame(maxWidth: 400)
    }
}
