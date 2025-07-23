//
//  LocalLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocalLoginViewSwiftUI: View {
    @ObservedObject var viewModel: LocalLoginViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Username
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.secondary)
                TextField("Username", text: $viewModel.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.username)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            // Password
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(Color.secondary)
                
                if viewModel.showPassword {
                    TextField("Password", text: $viewModel.password)
                        .textContentType(.password)
                } else {
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
                
                Button(action: {
                    viewModel.showPassword.toggle()
                    print("ShowPassword Toggled: \(viewModel.showPassword)")
                }) {
                    Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            // Sign In Button
            Button(action: { viewModel.loginTapped() }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            
            // Sign Up
            Button(action: { viewModel.signupTapped() }) {
                Text("Sign Up Here")
                    .foregroundStyle(Color.blue)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}


class PreviewLocalLoginViewModel: LocalLoginViewModel {
    override init(strategy: [String : Any] = [:], delegate: LoginDelegate? = nil) {
        super.init(strategy: strategy, delegate: delegate)
        self.username = "previewuser"
        self.password = "password123"
        self.showPassword = false
        self.isLoading = false
        self.errorMessage = nil
    }
    
    override func loginTapped() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            self.errorMessage = "Invalid login. Try again."
        }
    }
    
    override func signupTapped() {
        self.errorMessage = "Signup not implemented in preview."
    }
}

struct LocalLoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LocalLoginViewSwiftUI(viewModel: PreviewLocalLoginViewModel())
                .previewDisplayName("Default")
            LocalLoginViewSwiftUI(viewModel: {
                let vm = PreviewLocalLoginViewModel()
                vm.errorMessage = "Bad username or password!"
                return vm
            }())
            .previewDisplayName("With Error")
            LocalLoginViewSwiftUI(viewModel: {
                let vm = PreviewLocalLoginViewModel()
                vm.isLoading = true
                return vm
            }())
            .previewDisplayName("Loading State")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}

