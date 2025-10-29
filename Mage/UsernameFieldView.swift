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
    let cornerRadius: CGFloat = 8
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.secondary)
            TextField("Username", text: $username)
                .accessibilityLabel("Username")
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.username)
                .disabled(isDisabled || isLoading)
                .opacity((isDisabled || isLoading) ? 0.6 : 1)
                .focused($isTextFieldFocused)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.2))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius)) // Required for touch on transparent pixels
        )
        .onTapGesture { // Expand the touch area to the background shape
            isTextFieldFocused = true
        }
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
