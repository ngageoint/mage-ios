//
//  ServerFooter.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

// MARK: - Footer pinned at the bottom
struct ServerFooter: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                viewModel.onServerURLTapped()
            }) {
                Text(viewModel.serverURLLabel)
                    .underline(true)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if let v = viewModel.serverVersionLabel, !v.isEmpty {
                Text(v)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.001))
    }
}
