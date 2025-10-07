//
//  MageHeaderView.swift
//  Authentication
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct MageHeaderView: View {
    public let logoName: String
    public let title: String?
    public let subtitle: String?
    
    public init(logoName: String = "LogoClearTrimmed", title: String? = nil, subtitle: String? = nil) {
        self.logoName = logoName
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(logoName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .accessibilityHidden(true)
            
            if let title {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal)
    }
}

#Preview("MageHeaderView") {
    VStack(spacing: 24) {
        MageHeaderView(title: "Create Account", subtitle: "Sign up to get started")
        MageHeaderView(logoName: "LogoClear", title: nil, subtitle: nil)
    }
    .padding()
}
