//
//  LocalLoginViewNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocalLoginViewNextGen: View {
    @ObservedObject var viewModel: LoginViewModelNextGen
    let strategy: LoginStrategyNextGen
    let delegate: LoginDelegateNextGen
    
    @State private var isLoggingIn = false
    @State private var showPassword = false
    
    var onLoginTapped: () -> Void
    var onSignupTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if showPassword {
                TextField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }
            
            Toggle("Show Password", isOn: $showPassword)
                .padding(.bottom, 4)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Button("Sign In") {
                verifyLogin()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn || viewModel.username.isEmpty || viewModel.password.isEmpty)
            
            HStack {
                Text("New to Mage?")
                Button("Sign Up Here") {
                    onSignupTapped()
                }
            }
            .font(.footnote)
            .padding(.top, 4)
        }
        .padding()
    }
    
    private func verifyLogin() {
        isLoggingIn = true
        viewModel.errorMessage = nil
        
        Task {
            do {
                let user = try await strategy.login(username: viewModel.username, password: viewModel.password)
                isLoggingIn = false
                viewModel.username = ""
                viewModel.password = ""
                
                delegate.authenticationDidFinish(
                    status: .success,
                    user: user,
                    error: nil
                )
                onLoginTapped()
            } catch {
                isLoggingIn = false
                viewModel.errorMessage = error.localizedDescription
                
                delegate.authenticationDidFinish(
                    status: .error,
                    user: nil,
                    error: error
                )
            }
        }
    }
}

#if DEBUG
// For SwiftUI preview/testing
final class MockLoginDelegateNextGen: LoginDelegateNextGen {
    func authenticationDidFinish(
        status: AuthenticationStatusNextGen,
        user: UserNextGen?,
        error: Error?
    ) { }
    
    func createAccount() { }
}

struct MockLoginStrategyNextGen: LoginStrategyNextGen {
    var displayName: String { "Mock Local" }
    func login(username: String, password: String) async throws -> UserNextGen {
        if username == "admin" && password == "password" {
            return UserNextGen(username: username)
        } else {
            throw NSError(domain: "LocalLogin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }
}

struct LocalLoginViewNextGen_Previews: PreviewProvider {
    static var previews: some View {
        let mockDelegate = MockLoginDelegateNextGen()
        let mockStrategy = MockLoginStrategyNextGen()
        let viewModel = LoginViewModelNextGen(strategies: [mockStrategy], delegate: mockDelegate)
        
        LocalLoginViewNextGen(
            viewModel: viewModel,
            strategy: mockStrategy,
            delegate: mockDelegate,
            onLoginTapped: {},
            onSignupTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}


#endif

