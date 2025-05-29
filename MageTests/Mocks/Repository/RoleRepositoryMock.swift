//
//  RoleRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class RoleRepositoryMock: RoleRepository {
    var roles: [RoleModel] = []
    func getRole(remoteId: String) -> MAGE.RoleModel? {
        roles.first { model in
            model.remoteId == remoteId
        }
    }
}
