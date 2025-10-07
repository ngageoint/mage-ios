//
//  ChangePasswordView.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

public struct ChangePasswordView: View {
    @StateObject private var model: ChangePasswordViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(model: ChangePasswordViewModel) {
        _model = StateObject(wrappedValue: model)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Change Password").font(.title.bold())
            
            SecureField("Current Password", text: $model.currentPassword)
                .textContentType(.password)
                .submitLabel(.next)
            // TODO: FIX HELPER TEXT
            SecureField("New Password (helper text)", text: $model.newPassword)
                .textContentType(.newPassword)
                .submitLabel(.next)
            SecureField("Confirm New Password", text: $model.confirmNewPassword)
                .textContentType(.newPassword)
                .submitLabel(.go)
                .onSubmit { Task { await model.submit() } }
            
            if let err = model.errorMessage {
                Text(err).foregroundColor(.red).font(.footnote)
            }
            
            Button {
                Task { await model.submit() }
            } label: {
                if model.isSubmitting {
                    ProgressView()
                } else {
                    Text("Update Password").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.isFormValid || model.isSubmitting)
            
            Button("Cancel") { dismiss() }
                .buttonStyle(.borderless)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onChange(of: model.didSucceed) { ok in
            if ok { dismiss() }
        }
    }
}

