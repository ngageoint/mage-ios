//
//  LdapLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct LdapLoginViewSwiftUI: View {
    let strategy: LoginStrategy
    weak var delegate: LoginDelegate?
    var scheme: AppContainerScheming

    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("LDAP Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Login") {
//                delegate?.ldapLoginTapped(strategy, username: username, password: password)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
    }
}
