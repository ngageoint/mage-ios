//
//  UserModel.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct UserModel: Equatable, Hashable {
    var userId: URL?
    var remoteId: String?
    var name: String?
    var coordinate: CLLocationCoordinate2D?
    var email: String?
    var phone: String?
    var lastUpdated: Date?
    var avatarUrl: String?
    var username: String?
    var timestamp: Date?
    var hasEditPermissions: Bool = false
    var cllocation: CLLocation?
}

extension UserModel {
    init(user: User) {
        remoteId = user.remoteId
        name = user.name
        coordinate = user.coordinate
        email = user.email
        phone = user.phone
        lastUpdated = user.lastUpdated
        avatarUrl = user.cacheAvatarUrl
        username = user.username
        timestamp = user.location?.timestamp
        userId = user.objectID.uriRepresentation()
        hasEditPermissions = user.hasEditPermission
        cllocation = user.cllocation
    }
}
