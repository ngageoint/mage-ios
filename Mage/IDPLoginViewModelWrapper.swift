//
//  IDPLoginViewModelWrapper.swift
//  MAGE
//
//  Created by Brent Michalski on 7/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

@objc public protocol IDPLoginDelegate: NSObjectProtocol {
    @objc func signinForStrategy(_ strategy: NSDictionary)
}

@objc public class IDPLoginViewModelWrapper: NSObject {
    @objc public var viewModel: IDPLoginViewModel
    
    @objc public init(strategy: NSDictionary, delegate: IDPLoginDelegate?) {
        let swiftStrategy = strategy as? [String: Any] ?? [:]
        self.viewModel = IDPLoginViewModel(strategy: swiftStrategy, delegate: delegate)
        super.init()
    }
}

@objc public class IDPLoginViewHoster: NSObject {
    @objc public static func hostingController(withViewModel viewModel: IDPLoginViewModel) -> UIViewController {
        let swiftUIView = IDPLoginViewSwiftUI(viewModel: viewModel)
        return UIHostingController(rootView: swiftUIView)
    }
}
