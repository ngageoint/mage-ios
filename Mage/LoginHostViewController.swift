//
//  LoginHostViewController.swift
//  MAGE
//
//  Created by Brent Michalski on 8/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import SwiftUI

@objcMembers
public final class LoginHostViewController: UIViewController {
    
    private var viewModel: LoginRootViewModel
    private var host: UIHostingController<LoginRootViewSwiftUI>
    
    // MARK: - Obj-C compatible initializers
    public init(mageServer: MageServer,
                delegate: (NSObjectProtocol & LoginDelegate & IDPLoginDelegate),
                scheme: AnyObject? = nil) {
        
        self.viewModel = LoginRootViewModel(server: mageServer, user: nil, delegate: delegate)
        self.host = UIHostingController(rootView: LoginRootViewSwiftUI(viewModel: self.viewModel))
        super.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(mageServer: MageServer,
                            user: User,
                            delegate: (NSObjectProtocol & LoginDelegate & IDPLoginDelegate),
                            scheme: AnyObject? = nil) {
        
        self.init(mageServer: mageServer, delegate: delegate, scheme: scheme)
        self.viewModel = LoginRootViewModel(server: mageServer, user: user, delegate: delegate)
        self.host.rootView = LoginRootViewSwiftUI(viewModel: self.viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Backwards compatible "setMageServer"
    public func setMageServer(_ mageServer: MageServer) {
        self.viewModel = LoginRootViewModel(server: mageServer, user: viewModel.user, delegate: viewModel.delegate, loginFailure: viewModel.loginFailure)
        self.host.rootView = LoginRootViewSwiftUI(viewModel: self.viewModel)
    }
    
}
