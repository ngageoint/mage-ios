//
//  LoginRootViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 8/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class LoginRootViewModel: ObservableObject {
    // Inputs
    let server: MageServer?
    weak var delegate: AuthDelegates?
    let user: User?
    private let defaults: DefaultsStore

    // Optional override for previews/tests (does not persist)
    public var previewBaseURLOverride: String?
    
    // State
    @Published var loginFailure: Bool = false
    @Published var contactMessage: NSAttributedString?
    @Published var contactTitle: String?
    @Published var contactDetail: String?
    @Published var showContact: Bool = false
    @Published var showContactDetailButton: Bool = false
    
    init(server: MageServer?,
         user: User?,
         delegate: AuthDelegates?,
         loginFailure: Bool = false,
         defaults: DefaultsStore = SystemDefaults()  // Injectable defaults store to make testing & previews easier
    ) {
        self.server = server
        self.user = user
        self.delegate = delegate
        self.loginFailure = loginFailure
        self.defaults = defaults
    }
    
    var statusViewHidden: Bool { resolvedBaseURLString != nil }
    var serverURLButtonEnabled: Bool { true }
    
    private var resolvedBaseURLString: String? {
        if let override = previewBaseURLOverride, !override.isEmpty { return override }
        if let url = defaults.baseServerUrl, !url.isEmpty { return url }
        return nil
    }
    
    var isLocalOnly: Bool {
        let ids = strategies.compactMap { $0["identifier"] as? String }
        return ids.count == 1 && ids.first == StrategyKind.local.rawValue
    }
    
    var serverURLLabel: String {
        baseURLString ?? "Set Server URL"
    }
    
    var baseURLString: String? { resolvedBaseURLString }

    var serverVersionLabel: String? {
        let major = defaults.serverMajorVersion
        let minor = defaults.serverMinorVersion
        let micro = defaults.serverMicroVersion
        
        guard major > 0 else { return nil }
        
        let version = (micro > 0) ? "v\(major).\(minor).\(micro)" : "v\(major).\(minor)"
        let suffix = isLocalOnly ? StrategyKind.local.rawValue : nil
        return [version, suffix].compactMap { $0 }.joined(separator: " - ")
    }
    
    
    var versionAndStrategyText: String {
        serverVersionLabel ?? ""
    }
    
    func onServerURLTapped() { delegate?.changeServerURL() }
    
    func setContactInfo(_ contactInfo: ContactInfo) {
        contactMessage = contactInfo.messageWithContactInfo()
        contactTitle = contactInfo.title
        contactDetail = contactInfo.detailedInfo
        showContact = true
        showContactDetailButton = (contactInfo.detailedInfo.isEmpty == false)
    }
    
    func copyContactDetail() {
        guard let detail = contactDetail else { return }
        UIPasteboard.general.string = detail
    }
    
    var strategies: [[String: Any]] {
        if let stored = defaults.serverAuthenticationStrategies ?? defaults.authenticationStrategies {
            var nonLocal: [[String: Any]] = []
            var local:    [[String: Any]] = []
            for (key, payload) in stored {
                let dict: [String: Any] = ["identifier": key, "strategy": payload]
                
                if key == StrategyKind.local.rawValue {
                    local.append(dict)
                } else {
                    nonLocal.append(dict)
                }
            }
            nonLocal.sort { ($0["identifier"] as? String ?? "")  < ($1["identifier"] as? String ?? "") }
            return nonLocal + local
        }
        return (server?.strategies as? [[String: Any]]) ?? []
    }
    
    var hasLocal: Bool {
        strategies.contains { ($0["identifier"] as? String) == StrategyKind.local.rawValue }
    }

}

// Tap-to-dismiss helper
private struct KeyboardDismisser: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}


extension View {
    func dismissesKeyboardOnTap() -> some View {
        modifier(KeyboardDismisser())
    }
}
