//
//  OrViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct OrViewSwiftUI: View {
    var scheme: AppContainerScheming

    var body: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(Color(scheme.colorScheme.onSurfaceColor ?? .white).opacity(0.2))
            Text("OR")
                .font(.caption)
                .foregroundColor(Color(scheme.colorScheme.onSurfaceColor ?? .magenta).opacity(0.6))
            Rectangle().frame(height: 1).foregroundColor(Color(scheme.colorScheme.onSurfaceColor ?? .yellow).opacity(0.2))
        }
        .padding(.horizontal)
    }
}
