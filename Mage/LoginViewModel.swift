//
//  LoginViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var authStrategies: [LoginStrategy] = []
    @Published var contactInfoMessage: String?
    @Published var errorMessageDetail: String?

    var scheme: AppContainerScheming
    var server: MageServer
    var user: User?
    weak var delegate: LoginDelegate?

    init(server: MageServer, user: User?, scheme: AppContainerScheming, delegate: LoginDelegate?) {
        self.server = server
        self.user = user
        self.scheme = scheme
        self.delegate = delegate
        self.authStrategies = server.strategies?.compactMap { LoginStrategy(dictionary: $0) } ?? []
    }

    var serverURLDisplay: String {
        MageServer.baseURL()?.absoluteString ?? ""
    }

    var hasUser: Bool {
        user != nil
    }

    var shouldShowOrView: Bool {
        authStrategies.count > 1 && authStrategies.contains { $0.id == "local" }
    }

    func handleLogin() {
        print("Login tapped")
    }

    func handleSignup() {
        print("Signup tapped")
    }

    func onAppear() {
        print("LoginView appeared")
    }

    func copyErrorDetail() {
        UIPasteboard.general.string = errorMessageDetail
//        AlertManager.shared.showWithMessage("Error detail copied to clipboard", duration: 2.0, in: nil)
    }
}
