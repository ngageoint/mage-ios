//
//  OrDividerView.swift
//  MAGE
//
//  Created by Brent Michalski on 8/26/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

public struct OrDividerView: View {
    public init() {}
    
    public var body: some View {
        HStack {
            Divider()
            Text("OR")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
        }
    }
}
