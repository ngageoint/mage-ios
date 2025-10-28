//
//  LocalLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocalLoginViewSwiftUI: View {
    enum Field: Int, CaseIterable {
        case username
        case password
     }
    
    @ObservedObject var viewModel: LocalLoginViewModel
    @State var isIntroViewsShown: Bool = false
    @FocusState var focusedField: Field?
    
    var body: some View {
        VStack(spacing: 16) {
            UsernameFieldView(username: $viewModel.username, isDisabled: viewModel.userExists, isLoading: viewModel.isLoading)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            PasswordFieldView(password: $viewModel.password, showPassword: $viewModel.showPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    viewModel.loginTapped()
                }
                        
            SignInButtonView(isLoading: viewModel.isLoading) {
                viewModel.loginTapped()
            }
            .accessibilityLabel("Sign In")
            
            Text(viewModel.errorMessage ?? "")
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .opacity((viewModel.errorMessage != nil) ? 1 : 0)

            SignUpButtonView {
                viewModel.signupTapped()
            }
            
            MageIntroButtonView(isIntroViewsShown: $isIntroViewsShown)
        }
        .accessibilityIdentifier("Local Login View")
        .padding()
        .background(Color(.systemBackground))
        
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
        .previewLayout(.sizeThatFits)
    }
}


class PreviewLocalLoginViewModel: LocalLoginViewModel {
    init(strategy: [String : Any] = [:], delegate: LoginDelegate? = nil) {
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
