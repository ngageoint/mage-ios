//
//  MageServer+Testing.swift
//  MAGE
//
//  Created by Brent Michalski on 9/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

// TODO: BRENT - fix
//#if DEBUG
import Authentication

extension MageServer {
    func setAuthenticationModulesForTests(_ modules: [String: AuthenticationModule]) {
        self.authenticationModules = modules
    }
}
//#endif
