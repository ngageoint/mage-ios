//
//  ServerURLViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 7/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class ServerURLViewModel: ObservableObject {
    @Published var serverURL: String = MageServer.baseURL()?.absoluteString ?? ""
    @Published var showError: Bool = false
    @Published var showErrorDetails: Bool = false
    @Published var isLoading: Bool = false
    @Published var showCancelButton: Bool = false
    
    var scheme: AppContainerScheming?
    weak var delegate: ServerURLDelegate?
    var additionalErrorInfo: [String: Any]?
    
    var additionalErrorMessage: String? {
        guard let info = additionalErrorInfo else { return nil }
        let code = (info["statusCode"] as? Int).map(String.init) ?? "Unknown Error"
        let message = info["NSLocalizedDescription"] as? String ?? "Failed to connect to server."
        return "\(code): \(message)"
    }
    
    init(delegate: ServerURLDelegate, scheme: AppContainerScheming?) {
        self.delegate = delegate
        self.scheme = scheme
    }
    
    func submit() {
        guard !serverURL.isEmpty else {
            showError = true
            return
        }
        
        guard var components = URLComponents(string: serverURL) else {
            showError = true
            return
        }
        
        if components.path != "", components.host == nil {
            components.host = components.path
            components.path = ""
        }
        
        if components.path == "/" {
            components.path = ""
        }
        
        if components.scheme == nil {
            components.scheme = "https"
        }
        
        guard let url = components.url else {
            showError = true
            return
        }
        
        showError = false
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.delegate?.setServerURL(url: url)
            self.isLoading = false
        }
    }

    func cancel() {
        delegate?.cancelSetServerURL()
    }
    
    func showError(error: String, userInfo: [String: Any]?) {
        additionalErrorInfo = userInfo
        showError = true
        showErrorDetails = false
    }
}
