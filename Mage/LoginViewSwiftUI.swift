//
//  LoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LoginViewSwiftUI: View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.strategyType ?? "Unknown Strategy")
            
            UsernameFieldView(
                username: $viewModel.username,
                isDisabled: viewModel.userExists,
                isLoading: viewModel.isLoading,
                placeholder: viewModel.usernamePlaceholder
            )
            PasswordFieldView(
                password: $viewModel.password,
                showPassword: $viewModel.showPassword,
                placeholder: viewModel.passwordPlaceholder
            )
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .lineLimit(nil)
                    .foregroundColor(.red)
            }
            
            SignInButtonView(isLoading: viewModel.isLoading) {
                viewModel.loginTapped()
            }
            
            SignUpButtonView {
                viewModel.signupTapped()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginViewSwiftUI(viewModel: PreviewLoginViewModel())
                .previewDisplayName("Default")
            LoginViewSwiftUI(viewModel: {
                let vm = PreviewLoginViewModel()
                vm.errorMessage = "Bad username or password!"
                return vm
            }())
            .previewDisplayName("With Error")
            LoginViewSwiftUI(viewModel: {
                let vm = PreviewLoginViewModel()
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

class PreviewLoginViewModel: LoginViewModel {
    override init(strategy: [String : Any] = [:], delegate: LoginDelegate? = nil, user: User? = nil) {
        super.init(strategy: strategy, delegate: delegate, user: user)
        self.username = "ldapuser"
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
