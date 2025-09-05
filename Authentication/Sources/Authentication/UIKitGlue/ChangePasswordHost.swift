//
//  ChangePasswordHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import SwiftUI

@objc public final class ChangePasswordHost: UIViewController {
    private var hosting: UIHostingController<ChangePasswordViewSwiftUI>?
    
    // Swift-only DI entry point
    public static func make(auth: AuthService) -> ChangePasswordHost {
        let vm = ChangePasswordViewModel(auth: auth)
        let host = ChangePasswordHost()
        host.hosting = UIHostingController(rootView: ChangePasswordViewSwiftUI(model: vm))
        return host
    }
    
    
    // ObjC-Friendly
    @objc public static func make() -> ChangePasswordHost {
        guard let auth = AuthDependencies.shared.authService else { return ChangePasswordHost() }
        return make(auth: auth)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let hosting else { return }
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
}
