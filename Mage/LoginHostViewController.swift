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
    
    private final class DelegateAdapter: NSObject, AuthDelegates {
        weak var base: LoginDelegate?
        init(_ base: LoginDelegate?) { self.base = base }
        
        func changeServerURL() {
            print("LoginHostViewController.DelegateAdapter.changeServerURL")
            base?.changeServerURL()
        }
        
        func login(withParameters parameters: NSDictionary,
                   withAuthenticationStrategy authenticationStrategy: String,
                   complete: @escaping (AuthenticationStatus, String?) -> Void) {
            base?.login(withParameters: parameters,
                        withAuthenticationStrategy: authenticationStrategy,
                        complete: complete)
        }
        
        func createAccount() {
            base?.createAccount()
        }
        
        func signinForStrategy(_ strategy: NSDictionary) {
            base?.signinForStrategy(strategy)
        }
    }
    
    var debug_contactMessage: String? {
        viewModel.contactMessage?.string
    }
    
    private var viewModel: LoginRootViewModel
    private var host: UIHostingController<LoginRootView>
    private var composedDelegate: AuthDelegates?
    
    // MARK: - Designated Swift init
    private init(server: MageServer, user: User?, composedDelegate: AuthDelegates?, scheme: AnyObject?) {
        self.composedDelegate = composedDelegate
        self.viewModel = LoginRootViewModel(server: server, user: user, delegate: composedDelegate)
        let root = LoginRootView(viewModel: self.viewModel)
        self.host = UIHostingController(rootView: root)
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Obj-C compatible initializers
    
    private static func makeComposedDelegate(from delegate: LoginDelegate) -> AuthDelegates {
        (delegate as? AuthDelegates) ?? DelegateAdapter(delegate)
    }
    
    // 3-arg WITH “and”
    @objc(initWithMageServer:andDelegate:andScheme:)
    convenience init(mageServer: MageServer,
                     andDelegate delegate: LoginDelegate,
                     andScheme scheme: AnyObject? = nil) {
        let composed = Self.makeComposedDelegate(from: delegate)
        self.init(server: mageServer, user: nil, composedDelegate: composed, scheme: scheme)
    }
    
    // 3-arg NO “and”
    @objc(initWithMageServer:delegate:scheme:)
    convenience init(mageServerNoAnd mageServer: MageServer,
                     delegateNoAnd delegate: LoginDelegate,
                     schemeNoAnd scheme: AnyObject? = nil) {
        let composed = Self.makeComposedDelegate(from: delegate)
        self.init(server: mageServer, user: nil, composedDelegate: composed, scheme: scheme)
    }
    
    // 4-arg WITH “and”
    @objc(initWithMageServer:andUser:andDelegate:andScheme:)
    convenience init(mageServer: MageServer,
                     andUser user: User,
                     andDelegate delegate: LoginDelegate,
                     andScheme scheme: AnyObject? = nil) {
        let composed = Self.makeComposedDelegate(from: delegate)
        self.init(server: mageServer, user: user, composedDelegate: composed, scheme: scheme)
    }
    
    // 4-arg NO “and”
    @objc(initWithMageServer:user:delegate:scheme:)
    convenience init(mageServerNoAnd mageServer: MageServer,
                     userNoAnd user: User,
                     delegateNoAnd delegate: LoginDelegate,
                     schemeNoAnd scheme: AnyObject? = nil) {
        let composed = Self.makeComposedDelegate(from: delegate)
        self.init(server: mageServer, user: user, composedDelegate: composed, scheme: scheme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Backwards compatible "setMageServer"
    @objc(setMageServer:)
    func setMageServer(_ mageServer: MageServer) {
        self.viewModel = LoginRootViewModel(server: mageServer,
                                            user: viewModel.user,
                                            delegate: composedDelegate)
        self.host.rootView = LoginRootView(viewModel: self.viewModel)
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
