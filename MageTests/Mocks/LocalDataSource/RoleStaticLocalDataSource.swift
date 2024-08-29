//
//  RoleStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class RoleStaticLocalDataSource: RoleLocalDataSource {
    var roles: [RoleModel] = []
    func getRole(remoteId: String) -> MAGE.RoleModel? {
        roles.first { model in
            model.remoteId == remoteId
        }
    }
    
    func addUserToRole(roleJson: [AnyHashable : Any], user: MAGE.User, context: NSManagedObjectContext) {
        
    }
}
