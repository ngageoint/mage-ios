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
                Text("HEADER Create Account HEADER")
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
                        .submitLabel(.done)
                }
                .textFieldStyle(.roundedBorder)
                .disabled(model.isSubmitting)
                
                if let err = model.errorMessage {
                    Text(err).foregroundColor(.red).font(.footnote)
                }
                
                // CAPTCHA
                GroupBox("Human Verification") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // Prefer native image (crisp + no WebKit). Fallback to webview if decode fails.
                        if let img = model.captchaImage {
                            Image(uiImage: img)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .accessibilityIdentifier("captchaImageNative")
                        } else if !model.captchaHTML.isEmpty {
                            CaptchaWebView(html: model.captchaHTML)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .accessibilityIdentifier("captchaImageWeb")
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.secondarySystemFill))
                                    .frame(height: 120)
                                if model.isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("CAPTCHA will appear here")
                                        .font(.footnote)
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }
                        }
                        
                        TextField("Enter the characters", text: $model.captchaText)
                            .textFieldStyle(.roundedBorder)
                            .noAutoCapsAndCorrection()
                            .disabled(!captchaAvailable || model.isSubmitting)
                            .submitLabel(.done)
                            .onSubmit { Task { await model.completeSignup() } }
                            .accessibilityIdentifier("captchaTextField")
                        
                        HStack {
                            Button(captchaAvailable ? "Refresh" : "Load code") {
                                Task { await model.refreshCaptcha() }
                            }
                            .disabled(model.username.trimmingCharacters(in: .whitespaces).isEmpty || model.isSubmitting)
                            
                            Spacer()
                            
                            Button("Clear") {
                                model.captchaHTML = ""
                                model.captchaText = ""
                                model.captchaImage = nil
                            }
                            .disabled(!captchaAvailable || model.isSubmitting)
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
                if !model.username.trimmingCharacters(in: .whitespaces).isEmpty, !captchaAvailable {
                    Task { await model.refreshCaptcha() }
                }
            }
        }
    }
    
    // MARK: - Derived flags
    private var captchaAvailable: Bool {
        model.captchaImage != nil || !model.captchaHTML.isEmpty
    }
    
    private var canSubmit: Bool {
        model.isFormValid
        && captchaAvailable
        && !model.captchaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !model.isSubmitting
    }
}

// MARK: - Utilities

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
