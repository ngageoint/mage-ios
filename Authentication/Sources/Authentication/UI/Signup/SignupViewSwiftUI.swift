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
    
    @State private var attemtedAutoCaptchaLoad = false
    
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
                        .onChange(of: model.username) { newValue in
                            guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            if model.captchaHTML.isEmpty {
                                Task { await model.refreshCaptcha() }
                            }
                        }
                    
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
                        .submitLabel(.done)
                }
                .textFieldStyle(.roundedBorder)
                .disabled(model.isSubmitting)
                
                if let err = model.errorMessage {
                    Text(err).foregroundColor(.red).font(.footnote)
                }
                
                GroupBox("Human Verification") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        if !model.captchaHTML.isEmpty {
                            CaptchaWebView(html: model.captchaHTML)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 220)
                                .accessibilityIdentifier("captchaTextField")
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter a username, then tap 'Load code'.")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(UIColor.secondarySystemFill))
                                        .frame(height: 140)
                                    if model.isSubmitting {
                                        ProgressView()
                                    } else {
                                        Text("CAPTCHA will appear here")
                                            .font(.footnote)
                                            .foregroundStyle(Color(.secondaryLabel))
                                    }
                                }
                            }
                        }
                        
                        TextField("Enter the characters", text: $model.captchaText)
                            .textFieldStyle(.roundedBorder)
                            .noAutoCapsAndCorrection()
                            .disabled(model.captchaHTML.isEmpty || model.isSubmitting)
                            .submitLabel(.done)
                            .onSubmit { Task { await model.completeSignup() } }
                            .accessibilityIdentifier("captchaTextField")
                        
                        HStack {
                            Button(model.captchaHTML.isEmpty ? "Load code" : "Refresh") {
                                Task { await model.refreshCaptcha() }
                            }
                            .disabled(model.username.trimmingCharacters(in: .whitespaces).isEmpty || model.isSubmitting)
                            
                            Spacer()
                            
                            Button("Clear") {
                                model.captchaHTML = ""
                                model.captchaText = ""
                            }
                            .disabled(model.captchaHTML.isEmpty || model.isSubmitting)
                        }
                    }
                    .padding(.top, 4)
                }
                .accessibilityIdentifier("captchaGroupBox")
                
                // --------------------------------------------
                // SUBMIT ROW
                // --------------------------------------------
                HStack(spacing: 12) {
                    Button {
                        Task {
                            guard canSubmit else { return }
                            await model.completeSignup()
                        }
                    } label: {
                        if model.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Sign Up").bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit || model.isSubmitting)
                    
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.borderless)
                }
            }
            .padding()
            .onAppear {
                guard !attemtedAutoCaptchaLoad else { return }
                attemtedAutoCaptchaLoad = true
                if !model.username.trimmingCharacters(in: .whitespaces).isEmpty && model.captchaHTML.isEmpty {
                    Task { await model.refreshCaptcha() }
                }
            }
        }
    }
    
    private var canSubmit: Bool {
        model.isFormValid
        && !model.captchaHTML.isEmpty
        && !model.captchaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !model.isSubmitting
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
