//
//  SignupHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import SwiftUI

@objc public final class SignupHost: UIViewController {
    private var hosting: UIHostingController<SignupViewSwiftUI>?
    
    public static func make(auth: AuthService, sessionStore: SessionStore) -> SignupHost {
        let vm = SignupViewModel(auth: auth, sessionStore: sessionStore)
        let host = SignupHost()
        host.hosting = UIHostingController(rootView: SignupViewSwiftUI(model: vm))
        return host
    }
    
    @objc public static func make() -> SignupHost {
        guard let auth = AuthDependencies.shared.authService else { return SignupHost() }
        guard let store = SessionStoreDependencies.shared.sessionStore else { return SignupHost() }
        return make(auth: auth, sessionStore: store)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let hosting else { return }
        
        addChild(hosting)
        
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hosting.didMove(toParent: self)
    }
}
