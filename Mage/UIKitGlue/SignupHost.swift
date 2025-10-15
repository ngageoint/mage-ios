//
//  SignupHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Authentication

/// Obj-C facing factory. From Obj-C you can call: `[SignupHost make]`
@objc(AuthSignupHost)
final class SignupHost: AuthHostingController {

    init(policy: PasswordPolicy?, swiftDeps deps: AuthDependencies) {
        #if DEBUG
        let resolved = deps.resolvedForDebug()
        #else
        precondition(deps.authService  != nil, "AuthDependencies.authService must be injected")
        precondition(deps.sessionStore != nil, "AuthDependencies.sessionStore must be injected")
        let resolved = deps
        #endif
        
        let vm = SignupViewModel(deps: resolved, policy: policy)
        let view = SignupViewSwiftUI(model: vm)
        super.init(root: AnyView(view), title: "Create Account")
    }

    convenience init(swiftDeps deps: AuthDependencies) {
        let policy = MageServer.localPasswordPolicy
        self.init(policy: policy, swiftDeps: deps)
    }
    
    @objc convenience init() {
        let deps = AuthFactory.makeDeps()
        self.init(swiftDeps: deps)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
