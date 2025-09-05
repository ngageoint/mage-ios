//
//  SignupViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

public struct SignupViewSwiftUI: View {
    @StateObject private var model: SignupViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(model: SignupViewModel) {
        _model = StateObject(wrappedValue: model)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title.bold())
            
            Group {
                TextField("Display Name", text: $model.displayName)
                    .textContentType(.name)
                    .submitLabel(.next)
                TextField("Username", text: $model.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                TextField("Email", text: $model.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                SecureField("Password (help message)", text: $model.password)
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                SecureField("Confirm Password", text: $model.confirmPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .onSubmit { Task { await model.submit() } }
            }
            .textFieldStyle(.roundedBorder)
            
            if let err = model.errorMessage {
                Text(err).foregroundColor(.red).font(.footnote)
            }
            
            Button {
                Task { await model.submit() }
            } label: {
                if model.isSubmitting { ProgressView() } else { Text("Sign Up").bold() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.isFormValid || model.isSubmitting)
            
            Button("Cancel") { dismiss() }
                .buttonStyle(.borderless)
        }
        .padding()
        .onChange(of: model.didSucceed) { ok in if ok { dismiss() } }
        // TODO: Integrate theming, if we still want to
    }
}

//#Preview {
//    SignupViewSwiftUI()
//}
