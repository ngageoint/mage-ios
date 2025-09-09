//
//  LoginHostViewController.swift
//  MAGE
//
//  Created by Brent Michalski on 8/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import SwiftUI
import Authentication

@objc(LoginViewController)
@objcMembers
final class LoginHostViewController: UIViewController {
    
    var debug_contactMessage: String? {
        viewModel.contactMessage?.string
    }
    
    private var viewModel: LoginRootViewModel
    private var host: UIHostingController<LoginRootViewSwiftUI>
    
    // MARK: - Designated Swift init
    private init(server: MageServer, user: User?, delegate: LoginDelegate?, scheme: AnyObject?) {
        let composed = delegate as? AuthDelegates  // Swift-only composed protocols
        self.viewModel = LoginRootViewModel(server: server, user: user, delegate: composed)
        let root = LoginRootViewSwiftUI(viewModel: self.viewModel)
        self.host = UIHostingController(rootView: root)
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Obj-C compatible initializers
    // 3-arg WITH “and”
    @objc(initWithMageServer:andDelegate:andScheme:)
    convenience init(mageServer: MageServer,
                     andDelegate delegate: LoginDelegate,
                     andScheme scheme: AnyObject? = nil) {

        self.init(server: mageServer, user: nil, delegate: delegate, scheme: scheme)
    }
    
    // 3-arg NO “and”
    @objc(initWithMageServer:delegate:scheme:)
    convenience init(mageServerNoAnd mageServer: MageServer,
                     delegateNoAnd delegate: LoginDelegate,
                     schemeNoAnd scheme: AnyObject? = nil) {
        self.init(server: mageServer, user: nil, delegate: delegate, scheme: scheme)
    }
    
    // 4-arg WITH “and”
    @objc(initWithMageServer:andUser:andDelegate:andScheme:)
    convenience init(mageServer: MageServer,
                     andUser user: User,
                     andDelegate delegate: LoginDelegate,
                     andScheme scheme: AnyObject? = nil) {

        self.init(server: mageServer, user: user, delegate: delegate, scheme: scheme)
    }
    
    // 4-arg NO “and”
    @objc(initWithMageServer:user:delegate:scheme:)
    convenience init(mageServerNoAnd mageServer: MageServer,
                     userNoAnd user: User,
                     delegateNoAnd delegate: LoginDelegate,
                     schemeNoAnd scheme: AnyObject? = nil) {
        self.init(server: mageServer, user: user, delegate: delegate, scheme: scheme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Backwards compatible "setMageServer"
    @objc(setMageServer:)
    func setMageServer(_ mageServer: MageServer) {
        self.viewModel = LoginRootViewModel(server: mageServer,
                                            user: viewModel.user,
                                            delegate: viewModel.delegate)
        self.host.rootView = LoginRootViewSwiftUI(viewModel: self.viewModel)
    }
    
    @objc(setContactInfo:)
    func setContactInfo(_ contactInfo: ContactInfo) {
        viewModel.setContactInfo(contactInfo)
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        host.didMove(toParent: self)
    }
}
