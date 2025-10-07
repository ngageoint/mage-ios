//
//  DemoAllLoginViews.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

let demoStrategies: [[String: Any]] = [
    ["identifier": "local", "strategy": ["title": "Email"]],
    ["identifier": "ldap", "strategy": ["title": "LDAP"]],
    ["identifier": "idp", "strategy": ["title": "IDP", "name": "SSO"]]
]

struct DemoAllLoginViews: View {
    var body: some View {
        VStack(spacing: 24) {
            ForEach(Array(demoStrategies.enumerated()), id: \.offset) { _, strategy in
                if let identifier = strategy["identifier"] as? String {
                    if identifier == "local" || identifier == "ldap" {
                        LoginView(viewModel: LoginViewModel(strategy: strategy, delegate: nil))
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding()
                    } else if identifier == "idp" {
                        IDPLoginView(viewModel: IDPLoginViewModel(strategy: strategy, delegate: nil))
                            .padding()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("All Strategies Demo") {
    DemoAllLoginViews()
}

