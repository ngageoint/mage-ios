//
//  AuthenticationCoordinatorNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objcMembers
class AuthenticationCoordinatorNextGen: NSObject, LoginDelegateNextGen {
    let server: MageServer
    let scheme: AppContainerScheming
    let context: NSManagedObjectContext
    weak var delegate: AuthenticationDelegate?
    
    let viewModel: LoginViewModelNextGen
    
    init(server: MageServer, scheme: AppContainerScheming, context: NSManagedObjectContext, delegate: AuthenticationDelegate) async {
        self.server = server
        self.scheme = scheme
        self.context = context
        self.delegate = delegate
        
        let strategies: [LoginStrategyNextGen] = [
            LocalLoginStrategyNextGen(server: server),
            LdapLoginStrategyNextGen(server: server)
        ]
        
        let tempViewModel = await MainActor.run {
            LoginViewModelNextGen(strategies: strategies, delegate: nil)
        }
        
        self.viewModel = tempViewModel
        
        super.init()
        
        await MainActor.run {
            self.viewModel.delegate = self
        }
    }
    
    func authenticationDidFinish(status: AuthenticationStatusNextGen, user: UserNextGen?, error: Error?) {
        if status == .success {
            delegate?.authenticationSuccessful()
        } else if status == .unableToAuthenticate {
            delegate?.couldNotAuthenticate()
        }
    }
    
    func createAccount() {
        delegate?.createAccount()
    }
}
