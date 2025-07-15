//
//  LocalLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocalLoginViewSwiftUI: View {
    @ObservedObject var viewModel: LoginViewModel
    
//    @Binding var username: String
//    @Binding var password: String
    let strategy: LoginStrategy
    let delegate: LoginDelegate
//    let scheme: AppContainerScheming?
    
    @State private var isLoggingIn = false
    @State private var showPassword = false

    var onLoginTapped: () -> Void
    var onSignupTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)

            if showPassword {
                TextField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }
            
            Toggle("Show Password", isOn: $showPassword)

            Button("Sign In") {
                verifyLogin()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn)

            HStack {
                Text("New to MAGE?")
                Button("Sign Up Here") {
                    delegate.createAccount()
                }
            }
            .font(.footnote)
        }
        .padding()
    }
    
    private func verifyLogin() {
        isLoggingIn = true

        let parameters = buildLoginParameters()
        
        delegate.login(
            withParameters: parameters,
            withAuthenticationStrategy: strategy.id
        ) { status, error in
            handleAuthenticationResult(status)
        }
    }
    
    
    private func handleAuthenticationResult(_ status: AuthenticationStatus) {
        DispatchQueue.main.async {
            self.isLoggingIn = false

            // TODO: BRENT - CLEAN-UP
            switch status {
            case .AUTHENTICATION_SUCCESS:
                viewModel.username = ""
                viewModel.password = ""
                onLoginTapped()
            case .AUTHENTICATION_ERROR:
                print("!!! *** AUTHENTICATION_ERROR *** !!!")
                break
            case .REGISTRATION_SUCCESS:
                print("!!! *** REGISTRATION_SUCCESS *** !!!")
                break
            case .UNABLE_TO_AUTHENTICATE:
                print("!!! *** UNABLE_TO_AUTHENTICATE *** !!!")
                break
            default:
                print("!!! *** DEFAULT *** !!!")
                break
            }
        }
    }
    
    private func buildLoginParameters() -> [String: Any] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let appVersion = "\(version)-\(build)"
        let uuid = DeviceUUID.retrieveDeviceUUID()?.uuidString ?? ""
        
        return [
            "username": viewModel.username,
            "password": viewModel.password,
            "strategy": ["identifier": "local"],
            "uid": uuid,
            "appVersion": appVersion
        ]
    }
}

struct LocalLoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        let mockServer = MageServer(url: URL(string: "https://test.mage.geointapps.com")!)
        let mockScheme = AppDefaultContainerScheme()
        let mockDelegate = DummyLoginDelegate() as LoginDelegate
        let viewModel = LoginViewModel(server: mockServer, user: nil, scheme: mockScheme, delegate: mockDelegate)
        let mockStrategy = LoginStrategy(dictionary: ["identifier": "local"])!
        
        LocalLoginViewSwiftUI(viewModel: viewModel, strategy: mockStrategy, delegate: mockDelegate, onLoginTapped: {}, onSignupTapped: {})
            .previewLayout(.sizeThatFits)
    }
}


@objcMembers
public class LocalLoginViewWrapper: NSObject {
    @objc(newWithUsername:password:strategy:delegate:scheme:loginHandler:signupHandler:)
    static func newWithUsername(
        username: String,
        password: String,
        strategy: LoginStrategy,
        delegate: LoginDelegate,
        scheme: AppContainerScheming,
        loginHandler: @escaping () -> Void,
        signupHandler: @escaping () -> Void
    ) -> UIViewController {
        // TODO: BRENT - FORCE UNWRAP HERE NEEDS TO GO, TEMP FIX ONLY
        let server = MageServer(url: MageServer.baseURL()!)

        let user: User? = nil
        let viewModel = LoginViewModel(server: server, user: user, scheme: scheme, delegate: delegate)
        let swiftUIView = LocalLoginViewSwiftUI(viewModel: viewModel, strategy: strategy, delegate: delegate, onLoginTapped: loginHandler, onSignupTapped: signupHandler)

        return UIHostingController(rootView: swiftUIView)
    }
}
