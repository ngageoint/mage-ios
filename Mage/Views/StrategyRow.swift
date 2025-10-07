//
//  StrategyRow.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import SwiftUI

struct StrategyRow: View {
    let strategy: [String: Any]
    let user: User?
    let delegate: AuthDelegates?
    
    var body: some View {
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
            
            LoginView(viewModel: wrapper)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let idpViewModel = IDPLoginViewModelWrapper(strategy: strategy as NSDictionary,
                                                        delegate: delegate).viewModel
            
            IDPLoginView(viewModel: idpViewModel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
