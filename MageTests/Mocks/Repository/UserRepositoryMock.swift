//
//  UserRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class UserRepositoryMock: UserRepository {
    var currentUserUri: URL?
    var users: [UserModel] = []
    var canUpdateImportantReturnValue: Bool = true
    
    func getUser(userUri: URL?) async -> UserModel? {
        users.first { model in
            model.userId == userUri
        }
    }
    
    func getCurrentUser() -> UserModel? {
        if let currentUserUri = currentUserUri {
            return users.first { model in
                model.userId == currentUserUri
            }
        }
        
        if let currentUserRemoteId = UserDefaults.standard.currentUserId {
            return users.first { model in
                model.remoteId == currentUserRemoteId
            }
        }
        return nil
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        if let user = users.first(where: { model in
            model.userId == userUri
        }) {
            AnyPublisher(Just(user))
        } else {
            nil
        }
    }
    
    func getUser(remoteId: String) -> UserModel? {
        users.first { model in
            model.remoteId == remoteId
        }
    }
    
    func users(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        AnyPublisher(Just(users.compactMap{ model in
            model.userId
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    func canUserUpdateImportant(
        eventId: NSNumber,
        userUri: URL
    ) async -> Bool {
        canUpdateImportantReturnValue
    }
    
    func avatarChosen(user: UserModel, image: UIImage) async -> Bool {
        return true
    }
}
