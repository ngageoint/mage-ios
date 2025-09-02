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
    
    @Published var loginFailure: Bool = false
    
    @Published var contactMessage: NSAttributedString?
    @Published var contactTitle: String?
    @Published var contactDetail: String?
    @Published var showContact: Bool = false
    @Published var showContactDetailButton: Bool = false
    
    init(server: MageServer?,
         user: User?,
         delegate: AuthDelegates?,
         loginFailure: Bool = false) {
        self.server = server
        self.user = user
        self.delegate = delegate
        self.loginFailure = loginFailure
    }
    
    var statusViewHidden: Bool { server != nil }
    var serverURLButtonEnabled: Bool { server != nil }
    
    var baseURLString: String? {
        guard let url = MageServer.baseURL() else { return nil }
        return url.absoluteString
    }
    
    var versionAndStrategyText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let firstStrategy = (server?.strategies.first as? [String: Any])?["identifier"] as? String ?? "unknown"
        return "v\(version) - \(firstStrategy)"
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
        (server?.strategies as? [[String: Any]]) ?? []
    }
    
    var hasLocal: Bool {
        strategies.contains { ($0["identifier"] as? String) == "local" }
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
