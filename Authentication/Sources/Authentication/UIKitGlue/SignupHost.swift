//
//  SignupHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import UIKit

/// Obj-C facing factory. From Obj-C you can call: `[SignupHost make]`
@objc(SignupHost)
public final class SignupHostObjC: NSObject {
    /// Build the SwiftUI signup screen wrapped in a hosting controller.
    @MainActor
    @objc public static func make() -> UIViewController {
        let deps = AuthDependencies.shared
        
        // Fall back to preview types if the app hasn't injected real ones yet.
        let authService = deps.authService ?? PreviewAuthService()
        let sessionStore = deps.sessionStore ?? PreviewSessionStore()
        
        let viewModel = SignupViewModel(auth: authService, sessionStore: sessionStore)
        let root = SignupViewSwiftUI(model: viewModel)
        
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .systemBackground
        return host
    }
}
