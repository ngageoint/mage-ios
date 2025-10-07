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
