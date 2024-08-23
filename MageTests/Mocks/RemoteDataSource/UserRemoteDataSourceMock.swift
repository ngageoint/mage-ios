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
    
    var uploadAvatarUser: UserModel?
    var uploadAvatarImageData: Data?
    override func uploadAvatar(user: UserModel, imageData: Data) async -> [AnyHashable : Any] {
        uploadAvatarUser = user
        uploadAvatarImageData = imageData
        return ["userRemoteId":user.remoteId!]
    }
}
