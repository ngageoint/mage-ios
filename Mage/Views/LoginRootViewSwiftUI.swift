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

private struct MageHeaderView: View {
    var body: some View {
        Image("LogoClear")
            .renderingMode(.original) // to keep it's colors
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 240, maxHeight: 72)
            .accessibilityLabel("MAGE")
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, 4)
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
//                            print("\n---------------------------------------------")
//                            print("Calling: viewModel.onServerURLTapped()")
//                            print("---------------------------------------------\n")
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
                
//                if viewModel.isLocalOnly {
                    LocalOnlyLoginSection(viewModel: viewModel)
//                } else {
//                    StrategyStackView(viewModel: viewModel)
//                }
                
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
