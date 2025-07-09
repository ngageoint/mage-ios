//
//  LoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LoginViewSwiftUI: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MAGE title and wand
                Text("MAGE")
                    .font(.largeTitle)
                    .foregroundColor(Color(uiColor: viewModel.scheme.colorScheme.primaryColorVariant ?? .white))
                Text("\u{f0d0}") // wand
                    .font(.largeTitle)
                    .foregroundColor(Color(uiColor: viewModel.scheme.colorScheme.primaryColorVariant ?? .white))

                // Server URL
                if !viewModel.hasUser {
                    Button(action: {
                        viewModel.delegate?.changeServerURL()
                    }) {
                        Text(viewModel.serverURLDisplay)
                            .foregroundColor(Color(uiColor: viewModel.scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6) ?? UIColor.lightGray))
                    }
                }

                VStack(spacing: 16) {
                    ForEach(viewModel.authStrategies, id: \.id) { strategy in
                        switch strategy.id {
                        case "local":
                            LocalLoginViewSwiftUI(
                                username: viewModel.username,
                                password: viewModel.password,
                                onLoginTapped: viewModel.handleLogin,
                                onSignupTapped: viewModel.handleSignup
                            )
                        case "ldap":
                            LdapLoginViewSwiftUI(strategy: strategy, delegate: viewModel.delegate, scheme: viewModel.scheme)
                        default:
                            IDPLoginViewSwiftUI(strategy: strategy, delegate: viewModel.delegate, scheme: viewModel.scheme)
                        }
                    }

                    if viewModel.shouldShowOrView {
                        OrViewSwiftUI(scheme: viewModel.scheme)
                    }

                    if let message = viewModel.contactInfoMessage {
                        Text(message)
                            .font(.body)
                            .foregroundColor(viewModel.scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6))
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.errorMessageDetail != nil {
                        Button("Copy Error Message Detail") {
                            viewModel.copyErrorDetail()
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .padding()
        }
        .background(Color(uiColor: viewModel.scheme.colorScheme.backgroundColor ?? .white))
        .onAppear {
            viewModel.onAppear()
        }
    }
}


import SwiftUI

@objcMembers
class LoginViewSwiftUIWrapper: NSObject {
    static func make(server: MageServer, user: User?, scheme: AppContainerScheming, delegate: LoginDelegate?) -> UIViewController {
        let viewModel = LoginViewModel(server: server, user: user, scheme: scheme, delegate: delegate)
        return UIHostingController(rootView: LoginViewSwiftUI(viewModel: viewModel))
    }
}
