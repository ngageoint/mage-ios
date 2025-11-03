//
//  UserModel.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct UserModel: Equatable, Hashable {
    var active: NSNumber?
    var avatarUrl: String?
    var createdAt: Date?
    var cllocation: CLLocation?
    var coordinate: CLLocationCoordinate2D?
    var currentUser: NSNumber?
    var email: String?
    var iconUrl: String?
    var iconText: String?
    var iconColor: String?
    var hasEditPermissions: Bool = false
    var lastUpdated: Date?
    var location: Location?
    var name: String?
    var observations: Set<Observation>?
    var phone: String?
    var recentEventIds: [NSNumber]?
    var remoteId: String?
    var role: Role?
    var teams: Set<Team>?
    var timestamp: Date?
    var username: String?
    var userId: URL?
}

extension UserModel {
    init(user: User) {
        active = user.active
        avatarUrl = user.avatarUrl
        createdAt = user.createdAt
        cllocation = user.cllocation
        coordinate = user.coordinate
        currentUser = user.currentUser
        email = user.email
        iconUrl = user.iconUrl
        iconText = user.iconText
        iconColor = user.iconColor
        hasEditPermissions = user.hasEditPermission
        lastUpdated = user.lastUpdated
        location = user.location
        name = user.name
        observations = user.observations
        phone = user.phone
        recentEventIds = user.recentEventIds
        remoteId = user.remoteId
        role = user.role
        teams = user.teams
        timestamp = user.location?.timestamp
        username = user.username
        userId = user.objectID.uriRepresentation()
    }
}
