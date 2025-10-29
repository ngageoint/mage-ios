//
//  PasswordFieldView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct PasswordFieldView: View {
    enum Field {
        case passwordHidden
        case passwordVisible
    }
    
    @Binding var password: String
    @Binding var showPassword: Bool
    let cornerRadius: CGFloat = 8
    @FocusState var focusField: Field?

    var body: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundStyle(.secondary)
            
            ZStack { // Use opacity to toggle visibilty so that keyboard does not dismiss with the showPassword button
                // Use SecureField before TextField so that the default case will always show the cursor. Otherwise the TextField can have focus leaving the user without a cursor in the Password prompt (when hidden)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusField, equals: .passwordHidden)
                    .opacity(showPassword ? 0 : 1)
                
                TextField("Password", text: $password)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusField, equals: .passwordVisible)
                    .opacity(showPassword ? 1 : 0)
            }
     
            Button {
                showPassword.toggle()
                updateKeyboardFocus() // Update the focus to re-show the password, because it will defocus the text fields
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
            updateKeyboardFocus()
        }
    }
    
    func updateKeyboardFocus() {
        if showPassword {
            focusField = .passwordVisible
        } else {
            focusField = .passwordHidden
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
