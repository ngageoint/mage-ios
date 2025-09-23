//
//  LoginRootViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 8/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit
import Authentication

private struct MageHeaderView: View {
    @Environment(\.horizontalSizeClass) private var hsc
    
    var targetHeight: CGFloat?
    
    var body: some View {
        let base: CGFloat = (hsc == .regular) ? 84 : 60
        let desired: CGFloat = targetHeight ?? base
        let height: CGFloat = max(desired, 60)
        
        Image("LogoClearTrimmed")
            .renderingMode(.original) // to keep it's colors
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("MAGE")
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, 8)
    }
}

private struct ServerFooter: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                viewModel.onServerURLTapped()
            }) {
                Text(viewModel.serverURLLabel)
                    .underline(true)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if let v = viewModel.serverVersionLabel, !v.isEmpty {
                Text(v)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.001))
    }
}

struct LoginRootViewSwiftUI: View {
    @ObservedObject var viewModel: LoginRootViewModel
    @State private var showCopiedToast = false
    
    init(viewModel: LoginRootViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                if !viewModel.statusViewHidden {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Server not configured")
                            .font(.callout)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            print("\n---------------------------------------------")
                            print("Calling: viewModel.onServerURLTapped()")
                            print("---------------------------------------------\n")
                            viewModel.onServerURLTapped()
                        }) {
                            Text(viewModel.serverURLLabel)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .underline(true)
                                .contentShape(Rectangle())  // Makes the whole text area tappable
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    
                    Text(viewModel.versionAndStrategyText)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                
                if viewModel.isLocalOnly {
                    LocalOnlyLoginSection(viewModel: viewModel)
                } else {
                    StrategyStackView(viewModel: viewModel)
                }
                
                if viewModel.showContact, let attr = viewModel.contactMessage {
                    AttributedMessageView(attributed: attr, accessibilityLabel: viewModel.contactTitle)
                }
                
                if viewModel.showContactDetailButton {
                    Button("Copy Error Message Detail") {
                        viewModel.copyContactDetail()
                        withAnimation { showCopiedToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { showCopiedToast = false}
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .dismissesKeyboardOnTap()
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text("Error detail copied to clipboard")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}


// MARK: - Strategy Stack
private struct StrategyStackView: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.strategies.enumerated()), id: \.offset) { _, strategy in
                StrategyRow(strategy: strategy, user: viewModel.user, delegate: viewModel.delegate)
            }
            if viewModel.strategies.count > 1, viewModel.hasLocal {
                OrDividerView().padding(.vertical, 4)
            }
        }
    }
}


private struct StrategyRow: View {
    let strategy: [String: Any]
    let user: User?
    let delegate: AuthDelegates?
    
    var body: some View {
        let _ = print("QQQ: Identifier: \(strategy["identifier"] as? String ?? "N/A" )")
        
        // Render SwiftUI directly for Local/LDAP; use provided SwiftUI for IDP
        if (strategy["identifier"] as? String) == "local" ||
            (strategy["identifier"] as? String) == "ldap" {
            let wrapper: LoginViewModel = {
                if (strategy["identifier"] as? String) == "local" {
                    return LocalLoginViewModelWrapper(strategy: strategy as NSDictionary,
                                                      delegate: delegate,
                                                      user: user).viewModel
                } else {
                    return LdapLoginViewModelWrapper(strategy: strategy as NSDictionary,
                                                      delegate: delegate,
                                                      user: user).viewModel
                }
            }()
            
            LoginViewSwiftUI(viewModel: wrapper)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let idpViewModel = IDPLoginViewModelWrapper(strategy: strategy as NSDictionary,
                                                        delegate: delegate).viewModel
            
            IDPLoginViewSwiftUI(viewModel: idpViewModel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct AttributedMessageView: UIViewRepresentable {
    let attributed: NSAttributedString
    let accessibilityLabel: String?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.isAccessibilityElement = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributed
        uiView.accessibilityLabel = accessibilityLabel ?? "Message"
        uiView.textAlignment = .center
    }
}

// MARK: - Local-only layout
private struct LocalOnlyLoginSection: View {
    @ObservedObject var viewModel: LoginRootViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                MageHeaderView()
                
                Text("Sign in")
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("local_only_sign_in_title")
            }
            
            if let local = viewModel.strategies.first {
                StrategyRow(strategy: local, user: viewModel.user, delegate: viewModel.delegate)
            }
            
            // Footer goes here
        }
        .frame(maxWidth: 400)
    }
}


// MARK: - Previews
// NEW: MageHeaderView previews (compact, regular, dark)
//#if DEBUG
//
//#Preview("MageHeaderView • iPhone (compact)") {
//    MageHeaderView()
//        .padding(.horizontal, 20)
//        .frame(width: 390) // iPhone 15-ish width
//        .environment(\.horizontalSizeClass, .compact)
//}
//
//#Preview("MageHeaderView • iPad (regular)") {
//    MageHeaderView()
//        .padding(.horizontal, 24)
//        .frame(width: 834) // iPad Air portrait width
//        .environment(\.horizontalSizeClass, .regular)
//}
//
//#Preview("MageHeaderView • Dark Mode") {
//    MageHeaderView()
//        .padding(.horizontal, 20)
//        .frame(width: 390)
//        .environment(\.horizontalSizeClass, .compact)
//        .preferredColorScheme(.dark)
//}
//#endif

// MARK: - Previews
//#if DEBUG

// --- Preview helpers ---------------------------------------------------------

/// Strategy builders (match your production keys)
private enum PreviewStrategies {
    static func localOnly() -> [[String: Any]] {
        [
            ["identifier": "local", "title": "MAGE Username/Password"]
        ]
    }
    static func localAndLDAP() -> [[String: Any]] {
        [
            ["identifier": "local", "title": "MAGE Username/Password"],
            ["identifier": "ldap",  "title": "Enterprise Directory"]
        ]
    }
    static func localAndIDP() -> [[String: Any]] {
        [
            ["identifier": "local", "title": "MAGE Username/Password"],
            ["identifier": "idp",   "title": "Single Sign-On"]
        ]
    }
    static func all() -> [[String: Any]] {
        [
            ["identifier": "local", "title": "MAGE Username/Password"],
            ["identifier": "ldap",  "title": "Enterprise Directory"],
            ["identifier": "idp",   "title": "Single Sign-On"]
        ]
    }
}

/// No-op delegate for previews. Accept Xcode fix-its if your protocol adds methods.
private final class PreviewLoginDelegate: NSObject, AuthDelegates {
    @objc func login(withParameters parameters: NSDictionary,
                     withAuthenticationStrategy authenticationStrategy: String,
                     complete: @escaping (_ status: AuthenticationStatus, _ errorString: String?) -> Void) {
        // Preview: immediately return an "unable to authenticate" status
        complete(.unableToAuthenticate, nil)
    }

    @objc func changeServerURL() { /* no-op for previews */ }

    @objc func createAccount() { /* no-op for previews */ }

    @objc func signinForStrategy(_ strategy: NSDictionary) { /* no-op for previews */ }
}

/// Seeds UserDefaults so your VM reads the strategy list.
@MainActor
@discardableResult
private func makeLoginVM(strategies: [[String: Any]],
                         serverURL: String? = "https://demo.mage.example.org",
                         version: String? = "v4.3.0 - local") -> LoginRootViewModel {
    // Many MAGE paths store strategies in defaults under this key.
    UserDefaults.standard.set(strategies, forKey: "authenticationStrategies")

    // If your VM derives the URL/version from a server object, it’s fine to leave them nil.
    // The view already falls back to labels; otherwise wire a light-weight server if you have one.
    let delegate = PreviewLoginDelegate()
    let vm = LoginRootViewModel(server: nil, user: nil, delegate: delegate)

    // Optional: if your VM exposes these as settable, you can push preview values here.
    // Otherwise the footer will show "Set Server URL" which is fine for previews.
    // e.g. vm.previewBaseURL = serverURL ; vm.previewVersionLabel = version

    return vm
}

// --- Interactive configurator (live toggles in Preview) ----------------------

private struct LoginPreviewConfigurator: View {
    @State private var showLocal = true
    @State private var showLDAP  = false
    @State private var showIDP   = false
    @State private var headerHeight: CGFloat = 72

    private func currentStrategies() -> [[String: Any]] {
        var s: [[String: Any]] = []
        if showLocal { s.append(["identifier": "local", "title": "MAGE Username/Password"]) }
        if showLDAP  { s.append(["identifier": "ldap",  "title": "Enterprise Directory"]) }
        if showIDP   { s.append(["identifier": "idp",   "title": "Single Sign-On"]) }
        if s.isEmpty { s = PreviewStrategies.localOnly() } // guard against empty choice
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Controls
            GroupBox("Preview Controls") {
                VStack(alignment: .leading) {
                    Toggle("Local", isOn: $showLocal)
                    Toggle("LDAP",  isOn: $showLDAP)
                    Toggle("IDP",   isOn: $showIDP)

                    HStack {
                        Text("Header height: \(Int(headerHeight))")
                        Slider(value: $headerHeight, in: 60...120, step: 2)
                    }
                }
            }
            .padding(.horizontal, 16)

            Divider().padding(.vertical, 4)

            // Screen under test
            let vm = makeLoginVM(strategies: currentStrategies())
            LoginRootViewSwiftUI(viewModel: vm)
                .environment(\.horizontalSizeClass, .compact)
                .padding(.top, 8)
                .onAppear {
                    // If you exposed targetHeight on MageHeaderView, you can tweak with this env var or a static.
                    // Otherwise, pick the default you set in MageHeaderView (72 compact / 96 regular).
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
    }
}

// --- Snapshot previews --------------------------------------------------------

#Preview("Login • Local only") {
    let vm = makeLoginVM(strategies: PreviewStrategies.localOnly())
    return LoginRootViewSwiftUI(viewModel: vm)
        .frame(width: 390)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("Login • Local + LDAP") {
    let vm = makeLoginVM(strategies: PreviewStrategies.localAndLDAP())
    return LoginRootViewSwiftUI(viewModel: vm)
        .frame(width: 390)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("Login • Local + IDP") {
    let vm = makeLoginVM(strategies: PreviewStrategies.localAndIDP())
    return LoginRootViewSwiftUI(viewModel: vm)
        .frame(width: 390)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("Login • All Strategies • iPad") {
    let vm = makeLoginVM(strategies: PreviewStrategies.all())
    return LoginRootViewSwiftUI(viewModel: vm)
        .frame(width: 834) // iPad Air portrait
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Login • Interactive Configurator") {
    LoginPreviewConfigurator()
        .frame(width: 430) // iPhone Pro Max-ish
        .environment(\.horizontalSizeClass, .compact)
}

//#endif

