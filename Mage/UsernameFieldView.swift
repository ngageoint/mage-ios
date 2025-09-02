//
//  UsernameFieldView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct UsernameFieldView: View {
    @Binding var username: String
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var placeholder: String = "Username"
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.secondary)
            TextField(placeholder, text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.username)
                .disabled(isDisabled || isLoading)
                .opacity((isDisabled || isLoading) ? 0.6 : 1)
                .accessibilityLabel(placeholder)
                .accessibilityIdentifier(placeholder)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
    }
}

struct UsernameFieldView_Previews: PreviewProvider {
    @State static var username: String = "johndoe"
    
    static var previews: some View {
        Group {
            UsernameFieldView(username: $username)
                .previewDisplayName("Username Field - Default")
            UsernameFieldView(username: .constant(""))
                .previewDisplayName("Username Field - Empty")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemGroupedBackground))
    }
}
