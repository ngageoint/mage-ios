//
//  LocalLoginViewModelWrapper.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

@objc public class LocalLoginViewModelWrapper: NSObject {
    @objc public let viewModel: LocalLoginViewModel
    
    @objc public init(strategy: NSDictionary, delegate: LoginDelegate?, user: User?) {
        let swiftStrategy = strategy as? [String: Any]  ?? [:]
        self.viewModel = LocalLoginViewModel(strategy: swiftStrategy, delegate: delegate)
        
        if let user {
            self.viewModel.username = user.username ?? ""
        }
        
        super.init()
    }
}

@objc public class LocalLoginViewHoster: NSObject {
    /// Returns a ready-to-use UIHostingController containing the SwiftUI login view.
    @objc public static func hostingController(withViewModel viewModel: LocalLoginViewModel) -> UIViewController {
        let scheme = AppDefaultContainerScheme()
        let swiftUIView = LocalLoginViewSwiftUI(viewModel: viewModel)
        return UIHostingController(rootView: swiftUIView)
    }
}
