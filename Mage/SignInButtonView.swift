//
//  SignInButtonView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct SignInButtonView: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
            } else {
                Text("Sign In")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
        }
        .disabled(isLoading)
    }
}

struct SignInButtonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignInButtonView(isLoading: false) {}
                .previewDisplayName("Sign In Button")
            SignInButtonView(isLoading: true) {}
                .previewDisplayName("Sign In Button - Loading")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemGroupedBackground))
    }
}
