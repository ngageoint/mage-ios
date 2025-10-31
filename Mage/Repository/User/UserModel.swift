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
        active = user.active // NSNumber?
        avatarUrl = user.avatarUrl // String?
        createdAt = user.createdAt // Date?
        cllocation = user.cllocation // CLLocation?
        coordinate = user.coordinate // CLLocationCoordinate2D?
        currentUser = user.currentUser // NSNumber?
        email = user.email // String?
        iconUrl = user.iconUrl // String?
        iconText = user.iconText // String?
        iconColor = user.iconColor // String?
        hasEditPermissions = user.hasEditPermission
        lastUpdated = user.lastUpdated // Date?
        location = user.location // Location?
        name = user.name // String?
        observations = user.observations // Set<Observation>?
        phone = user.phone // String?
        recentEventIds = user.recentEventIds // [NSNumber]?
        remoteId = user.remoteId // String?
        role = user.role // Role?
        teams = user.teams // Set<Team>?
        timestamp = user.location?.timestamp // Date?
        username = user.username // String?
        userId = user.objectID.uriRepresentation() // URL?
    }
}
