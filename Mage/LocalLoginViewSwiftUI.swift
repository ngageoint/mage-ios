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
//    var scheme: AppContainerScheming
    
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
                    Text("Sign In Eh?")
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
                Text("Sign Up Here Eh?")
                    .foregroundStyle(Color.blue)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
