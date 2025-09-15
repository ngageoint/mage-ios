//
//  ChangePasswordHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

/// Obj-C visible wrapper that keeps the legacy name and entry point.
/// Usage from Obj-C stays: `[ChangePasswordHost make]`
@objc(ChangePasswordHost)
public final class ChangePasswordHostObjC: NSObject {
    @MainActor
    @objc public static func make() -> UIViewController {
        let deps = AuthDependencies.shared
        let auth = deps.authService ?? PreviewAuthService()
        
        let vm = ChangePasswordViewModel(auth: auth)
        let root = ChangePasswordViewSwiftUI(model: vm)
        
        let vc = UIHostingController(rootView: root)
        vc.view.backgroundColor = .systemBackground
        return vc
    }
}
