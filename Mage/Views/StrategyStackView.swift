//
//  StrategyStackView.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import SwiftUI

// MARK: - Strategy Stack
struct StrategyStackView: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.strategies.enumerated()), id: \.offset) { _, strategy in
                StrategyRow(strategy: strategy, user: viewModel.user, delegate: viewModel.delegate)
            }
            if viewModel.strategies.count > 1, viewModel.hasLocal {
                OrDividerView().padding(.vertical, 4)
            }
        }
    }
}
