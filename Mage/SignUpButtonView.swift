//
//  SignUpButtonView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct SignUpButtonView: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text("New to MAGE?")
            Spacer()
            Button(action: action) {
                Text("Sign Up Here")
                    .foregroundStyle(Color.blue)
            }
        }
        .padding(.top, 8)
    }
}

struct SignUpButtonView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpButtonView { }
            .padding()
            .previewLayout(.sizeThatFits)
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Sign Up Button")
    }
}
