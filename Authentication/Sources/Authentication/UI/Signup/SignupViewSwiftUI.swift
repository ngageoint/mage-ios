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
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Account (HEADER!)")
                    .font(.title.bold())
                
                Group {
                    TextField("Display Name", text: $model.displayName)
                        .noAutoCapsAndCorrection()
                        .textContentType(.name)
                        .submitLabel(.next)
                    
                    TextField("Username", text: $model.username)
                        .noAutoCapsAndCorrection()
                        .textContentType(.username)
                        .submitLabel(.next)
                    
                    TextField("Email", text: $model.email)
                        .noAutoCapsAndCorrection()
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .submitLabel(.next)
                    
                    SecureField("Password (NEED Verification DATA)", text: $model.password)
                        .textContentType(.newPassword)
                        .submitLabel(.next)
                    
                    SecureField("Confirm Password", text: $model.confirmPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                guard model.isFormValid else { return }
                                await model.beginSignup()
                            }
                        }
                }
                .textFieldStyle(.roundedBorder)
                .disabled(model.isSubmitting)
                
                if let err = model.errorMessage {
                    Text(err).foregroundColor(.red).font(.footnote)
                }
                
                HStack(spacing: 12) {
                    Button {
                        Task {
                            // validate form first
                            guard model.isFormValid else { return }
                            await model.beginSignup()
                        }
                    } label: {
                        if model.isSubmitting { ProgressView() } else { Text("Sign Up").bold() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.isFormValid || model.isSubmitting)
                    
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.borderless)
                }
                
                if model.showCaptcha {
                    GroupBox("Human Verification") {
                        VStack(alignment: .leading, spacing: 12) {
                            CaptchaWebView(html: model.captchaHTML)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 220)
                                .accessibilityIdentifier("captchaTextField")
                            
                            HStack {
                                Button {
                                    Task { await model.refreshCaptcha() }
                                } label: {
                                    if model.isSubmitting { ProgressView() } else { Text("Refresh") }
                                }
                                
                                Spacer()
                                
                                Button("Cancel") { model.showCaptcha = false }
                                
                                Button {
                                    Task { await model.completeSignup() }
                                } label: {
                                    if model.isSubmitting { ProgressView() } else { Text("Submit").bold() }
                                }
                                .disabled(model.captchaText.isEmpty || model.isSubmitting)
                                .accessibilityIdentifier("captchaSubmitButton")
                            }
                        }
                        .padding(.top, 4)
                    }
                    .accessibilityIdentifier("captchaGroupBox")
                }
            }
            .padding()
        }  // Scrollview
    }
}

private struct NoAutoCapsAndCorrection: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } else {
            content.autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

private extension View {
    func noAutoCapsAndCorrection() -> some View { modifier(NoAutoCapsAndCorrection()) }
}
