//
//  LdapLoginViewModelWrapper.swift
//  MAGE
//
//  Created by Brent Michalski on 7/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Authentication

@MainActor
@objc public class LdapLoginViewModelWrapper: NSObject {
    @objc public let viewModel: LoginViewModel

    @objc public init(strategy: NSDictionary, delegate: LoginDelegate?, user: User?) {
        let swiftStrategy = strategy as? [String: Any] ?? [:]
        self.viewModel = LoginViewModel(strategy: swiftStrategy, delegate: delegate, user: user)
        super.init()
    }
}

@MainActor
@objc public class LdapLoginViewHoster: NSObject {
    @objc public static func hostingController(withViewModel viewModel: LoginViewModel) -> UIViewController {
        let swiftUIView = LoginViewSwiftUI(viewModel: viewModel)
        return UIHostingController(rootView: swiftUIView)
    }
}
