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
    var onLoginTapped: () -> Void
    var onSignupTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Toggle("Show Password", isOn: .constant(false))

            Button("Sign In") {
                onLoginTapped()
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Text("New to MAGE?")
                Button("Sign Up Here") {
                    onSignupTapped()
                }
            }
            .font(.footnote)
        }
        .padding()
    }
}

struct LocalLoginViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        LocalLoginViewSwiftUI(
            username: .constant(""),
            password: .constant(""),
            onLoginTapped: {},
            onSignupTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}


@objcMembers
public class LocalLoginViewWrapper: NSObject {
    @objc static func newWithUsername(
        _ username: String,
        password: String,
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

        let swiftUIView = LocalLoginViewSwiftUI(
            username: user,
            password: pass,
            onLoginTapped: loginHandler,
            onSignupTapped: signupHandler
        )

        return UIHostingController(rootView: swiftUIView)
    }
}
