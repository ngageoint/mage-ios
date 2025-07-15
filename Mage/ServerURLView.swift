//
//  ServerURLView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ServerURLView: View {
    
    @State private var urlText: String = ""
    @State private var isValidURL = false
    @State private var showError = false
    @State private var errorText = "This URL does not appear to be a MAGE server."
    @State private var showProgress = false
    @State private var showCancel = true
    @State private var showErrorDetails = false
    
    let delegate: ServerURLDelegate
    let error: String?
    let additionalErrorInfo: [String: Any]?
    let scheme: AppContainerScheming?
    
    var body: some View {
        VStack(spacing: 16) {
            wandAndMageHeader
            
            Text("Set MAGE Server URL")
                .font(.headline6)
                .foregroundColor(Color(scheme?.colorScheme.primaryColorVariant ?? .label))
            
            ThemedTextFieldView(
                title: "MAGE Server URL",
                text: $urlText,
                placeholder: "MAGE Server URL",
                iconSystemName: "globe.americas.fill",
                scheme: scheme
            )
            .keyboardType(.URL)
            
            HStack(spacing: 16) {
                if showCancel {
                    Button("Cancel") {
                        delegate.cancelSetServerURL()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("OK") {
                    handleOkTapped()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if showProgress {
                ProgressView()
            }
            
            if showError {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color(scheme?.colorScheme.errorColor ?? .red))
                    Text(errorText)
                        .foregroundColor(.secondary)
                }
                
                if showErrorDetails {
                    Button("More Info") {
                        showErrorAlert()
                    }
                    .font(.footnote)
                }
            }
        }
        .padding()
        .onAppear {
            let base = MageServer.baseURL()?.absoluteString ?? ""
            urlText = base
            if error != nil {
                showError = true
                showCancel = false
            }
        }
    }
    
    var wandAndMageHeader: some View {
        HStack(spacing: 8) {
            Text("\u{0000f0d0}")
                .font(.custom("FontAwesome", size: 50))
                .foregroundColor(Color(scheme?.colorScheme.primaryColorVariant ?? .label))
            
            Text("MAGE")
                .font(.custom("GondolaMageRegular", size: 52))
                .foregroundColor(Color(scheme?.colorScheme.primaryColorVariant ?? .label))
        }
    }
    
    func handleOkTapped() {
        guard var urlComponents = URLComponents(string: urlText) else {
            showInvalidURL()
            return
        }
        
        if urlComponents.path != "", urlComponents.host == nil {
            urlComponents.host = urlComponents.path
            urlComponents.path = ""
        }
        
        if urlComponents.path == "/" {
            urlComponents.path = ""
        }
        
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        }
        
        guard let url = urlComponents.url else {
            showInvalidURL()
            return
        }
        
        showProgress = true
        showError = false
        delegate.setServerURL(url: url)
    }
    
    func showInvalidURL() {
        showError = true
        showErrorDetails = true
        showProgress = false
    }
    
    func showErrorAlert() {
        let title = String((additionalErrorInfo?["statusCode"] as? Int) ?? 400)
        let message = additionalErrorInfo?["NSLocalizedDescription"] as? String ?? "Failed to connect to server."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
    
}
