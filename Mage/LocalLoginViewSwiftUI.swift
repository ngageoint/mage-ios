//
//  LocalLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LocalLoginViewSwiftUI: View {
    @Binding var username: String
    @Binding var password: String
    let strategy: LoginStrategy
    let delegate: LoginDelegate
    let scheme: AppContainerScheming?
    
    @State private var isLoggingIn = false
    @State private var showPassword = false

    var onLoginTapped: () -> Void
    var onSignupTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)

            if showPassword {
                TextField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField("Password", text: $password)
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

        let deviceUUID = DeviceUUID.retrieveDeviceUUID()?.uuidString
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let appVersion = "\(version)-\(build)"

        let parameters: [String: String] = [
//            "username": username,
//            "password": password,
            "username": "bmichalski",
            "password": "Password123456",
            "strategy": strategy.id,
            "uid": deviceUUID ?? "",
            "appVersion": appVersion
        ]
        
        delegate.login(withParameters: parameters, withAuthenticationStrategy: strategy.objcDictionary) { status, error in
            DispatchQueue.main.async {
                isLoggingIn = false

                switch status {
                case .AUTHENTICATION_SUCCESS:
                    username = ""
                    password = ""
                case .REGISTRATION_SUCCESS, .UNABLE_TO_AUTHENTICATE:
                    break
                default:
                    break
                }
            }
        }
    }
}

struct LocalLoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        LocalLoginViewSwiftUI(
            username: .constant(""),
            password: .constant(""),
            strategy: LoginStrategy(dictionary: ["identifier": "local"])!,
            delegate: DummyLoginDelegate() as LoginDelegate,    // mock delegate
            scheme: AppDefaultContainerScheme(), // mock or real scheme
            onLoginTapped: {},
            onSignupTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}


@objcMembers
public class LocalLoginViewWrapper: NSObject {
    @objc(newWithUsername:password:strategy:delegate:scheme:loginHandler:signupHandler:)
    static func newWithUsername(
        _ username: String,
        password: String,
        strategy: LoginStrategy,
        delegate: LoginDelegate,
        scheme: AppContainerScheming,
        loginHandler: @escaping () -> Void,
        signupHandler: @escaping () -> Void
    ) -> UIViewController {
        let user = Binding<String>(
            get: { username },
            set: { _ in }
        )

        let pass = Binding<String>(
            get: { password },
            set: { _ in }
        )

        // TODO: BRENT - FORCE UNWRAP HERE NEEDS TO GO, TEMP FIX ONLY
        let swiftUIView = LocalLoginViewSwiftUI(
            username: user,
            password: pass,
            strategy: strategy,
            delegate: delegate,
            scheme: scheme,
            onLoginTapped: loginHandler,
            onSignupTapped: signupHandler
        )

        return UIHostingController(rootView: swiftUIView)
    }
}
