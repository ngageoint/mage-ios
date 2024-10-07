//
//  UserRemoteDataSourceMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class UserRemoteDataSourceMock: UserRemoteDataSource {
    var fetchMyselfResponse: [AnyHashable: Any]?
    var fetchMyselfCalled = false
    func fetchMyself() async -> [AnyHashable : Any]? {
        fetchMyselfCalled = true
        return fetchMyselfResponse
    }
    
    
    var uploadAvatarUser: UserModel?
    var uploadAvatarImageData: Data?
    func uploadAvatar(user: UserModel, imageData: Data) async -> [AnyHashable : Any] {
        uploadAvatarUser = user
        uploadAvatarImageData = imageData
        return ["userRemoteId":user.remoteId!]
    }
}
