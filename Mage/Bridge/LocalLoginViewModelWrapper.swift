//
//  LocalLoginViewModelWrapper.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Authentication

/// Wraps the SwiftUI LoginViewModel for Objective-C/legacy call sites.
/// Marked @MainActor because LoginViewModel is @MainActor and we mutate UI state.
@MainActor
@objc public final class LocalLoginViewModelWrapper: NSObject {
    @objc public let viewModel: LoginViewModel
    
    /// Obj-C entry point
    @objc public init(strategy: NSDictionary, delegate: LoginDelegate?, user: User?) {
        let swiftStrategy = strategy as? [String: Any]  ?? [:]
        self.viewModel = LoginViewModel(strategy: swiftStrategy, delegate: delegate, user: user)
        super.init()
        
        if let user {
            self.viewModel.username = user.username ?? ""
        }
    }
}

/// Factory that returns a ready-to-use hosting controller for the SwiftUI login view.
/// Also @MainActor because it builds UI.
@MainActor
@objc public final class LocalLoginViewHoster: NSObject {
    /// Returns a ready-to-use UIHostingController containing the SwiftUI login view.
    @objc public static func hostingController(withViewModel viewModel: LoginViewModel) -> UIViewController {
        let swiftUIView = LoginView(viewModel: viewModel)
        let host = UIHostingController(rootView: swiftUIView)
        host.view.backgroundColor = .clear
        return host
    }
}
