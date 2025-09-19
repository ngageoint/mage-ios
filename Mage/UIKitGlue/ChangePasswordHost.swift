//
//  ChangePasswordHost.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Authentication

@objc(AuthChangePasswordHost)
final class ChangePasswordHost: AuthHostingController {
    init(swiftDeps deps: AuthDependencies) {
        #if DEBUG
        let resolved = deps.resolvedForDebug()
        #else
        precondition(deps.authService != nil,  "AuthDependencies.authService must be injected")
        precondition(deps.sessionStore != nil, "AuthDependencies.sessionStore must be injected")
        let resolved = deps
        #endif
        
        let vm = ChangePasswordViewModel(deps: resolved)
        
                
    }
    

}
