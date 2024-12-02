//
//  ObservationImportantModel.swift
//  MAGETests
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationImportantModel: Equatable, Hashable {
    static func == (lhs: ObservationImportantModel, rhs: ObservationImportantModel) -> Bool {
        lhs.userId == rhs.userId && lhs.timestamp == rhs.timestamp
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(timestamp)
    }
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    var important: Bool
    var userId: String?
    var reason: String?
    var timestamp: Date?
    var observationRemoteId: String?
    var importantUri: URL
    var eventId: NSNumber?
    
    var userName: String? {
        if let userId = userId {
            let user = userRepository.getUser(remoteId: userId)
            return user?.name
        }
        return nil
    }
}

extension ObservationImportantModel {
    init(observationImportant: ObservationImportant) {
        self.importantUri = observationImportant.objectID.uriRepresentation()
        self.observationRemoteId = observationImportant.observation?.remoteId
        self.important = observationImportant.important
        self.userId = observationImportant.userId
        self.reason = observationImportant.reason
        self.timestamp = observationImportant.timestamp
        self.eventId = observationImportant.observation?.eventId
    }
}
