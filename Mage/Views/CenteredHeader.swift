//
//  CenteredHeader.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import SwiftUI

struct CenteredHeader: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.title2.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityIdentifier("sign_in_title")
    }
}

struct CenteredHeader_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUI.Group {
            CenteredHeader(text: "Sign In")
                .padding()
                .previewDisplayName("Short")

            CenteredHeader(text: "Welcome to MAGE\nPlease sign in to continue")
                .padding()
                .previewDisplayName("Multiline")

            CenteredHeader(text: "Sign In – Large Type")
                .padding()
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("AX Large Type")
        }
        .previewLayout(.sizeThatFits)
    }
}
