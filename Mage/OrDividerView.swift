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

// MARK: - Previews
//#if DEBUG
import SwiftUI

struct OrDividerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OrDividerView()
                .padding()
                .previewDisplayName("Default")
                .previewLayout(.sizeThatFits)

            SwiftUI.Form { OrDividerView() }
                .previewDisplayName("In Form")
                .previewLayout(.sizeThatFits)
        }
    }
}
//#endif
