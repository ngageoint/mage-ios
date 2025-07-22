//
//  SwiftUILoginLauncher.swift
//  MAGE
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

@objcMembers
class SwiftUILoginLauncher: NSObject {
    @MainActor
    static func makeLoginViewController(
        server: MageServer,
        scheme: AppContainerScheming,
        context: NSManagedObjectContext,
        delegate: AuthenticationDelegate
    ) async -> UIViewController {
        let coordinator = await AuthenticationCoordinatorNextGen(
            server: server,
            scheme: scheme,
            context: context,
            delegate: delegate
        )
        
        let view = AuthenticationRootViewNextGen(coordinator: coordinator)
        let host = UIHostingController(rootView: view)
        host.modalPresentationStyle = .fullScreen
        return host
    }
    
}
