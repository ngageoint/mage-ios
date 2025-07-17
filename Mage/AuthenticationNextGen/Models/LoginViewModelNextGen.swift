//
//  LoginViewModelNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@MainActor
class LoginViewModelNextGen: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    var strategies: [LoginStrategyNextGen]
    weak var delegate: LoginDelegateNextGen?
    
    init(strategies: [LoginStrategyNextGen], delegate: LoginDelegateNextGen? = nil) {
        self.strategies = strategies
        self.delegate = delegate
    }

    // Generic Login Function
    func login(using strategy: LoginStrategyNextGen) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await strategy.login(username: username, password: password)
            isLoading = false
            
            delegate?.authenticationDidFinish(
                status: .success,
                user: user,
                error: nil
            )
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            
            delegate?.authenticationDidFinish(
                status: .error,
                user: nil,
                error: error
            )
        }
    }
    
    func clearFields() {
        username = ""
        password = ""
        errorMessage = nil
    }
}

