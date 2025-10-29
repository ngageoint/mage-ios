//
//  PasswordFieldView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct PasswordFieldView: View {
    @Binding var password: String
    @Binding var showPassword: Bool
    @FocusState var isPasswordFocused: Bool
    let cornerRadius: CGFloat = 8

    var body: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundStyle(.secondary)
            
            ZStack { // Use opacity to toggle visibilty so that keyboard does not dismiss
                TextField("Password", text: $password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isPasswordFocused)
                    .opacity(showPassword ? 1 : 0)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isPasswordFocused)
                    .opacity(showPassword ? 0 : 1)
            }
            
            Button {
                showPassword.toggle()
                isPasswordFocused = true  // maintain keyboard focus
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.2))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius)) // Allow transparent pixels to be tappable
        )
        .onTapGesture {
            isPasswordFocused = true // Expand touch area to border padding
        }
    }
}

struct PasswordFieldView_Previews: PreviewProvider {
    @State static var password: String = "mypassword"
    @State static var showPassword: Bool = false

    static var previews: some View {
        Group {
            PasswordFieldView(password: $password, showPassword: $showPassword)
                .previewDisplayName("Password Field - Hidden")
            PasswordFieldView(password: .constant("secret"), showPassword: .constant(true))
                .previewDisplayName("Password Field - Visible")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemGroupedBackground))
    }
}
