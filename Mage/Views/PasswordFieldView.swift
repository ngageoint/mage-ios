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
    var placeholder: String = "Password"
    
    var body: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundStyle(.secondary)
            
            if showPassword {
                TextField(placeholder, text: $password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier(A11yID.loginPassword)
            } else {
                SecureField(placeholder, text: $password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier(A11yID.loginPassword)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            .accessibilityIdentifier("Toggle Password Visibility")
        }
        .accessibilityElement(children: .contain)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
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
