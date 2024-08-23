//
//  UserStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class UserStaticLocalDataSource: UserLocalDataSource {
    var currentUserUri: URL?
    var users: [UserModel] = []
    var canUpdateImportantReturnValue: Bool = true
    
    func getUser(userUri: URL?) async -> MAGE.UserModel? {
        users.first { model in
            model.userId == userUri
        }
    }
    
    func getCurrentUser() -> MAGE.UserModel? {
        if let currentUserUri = currentUserUri {
            return users.first { model in
                model.userId == currentUserUri
            }
        }
        return nil
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<MAGE.UserModel, Never>? {
        if let user = users.first(where: { model in
            model.userId == userUri
        }) {
            AnyPublisher(Just(user))
        } else {
            nil
        }
    }
    
    func getUser(remoteId: String) -> MAGE.UserModel? {
        users.first { model in
            model.remoteId == remoteId
        }
    }
    
    func users(paginatedBy paginator: MAGE.Trigger.Signal?) -> AnyPublisher<[MAGE.URIItem], any Error> {
        AnyPublisher(Just(users.compactMap{ model in
            model.userId
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    func canUserUpdateImportant(event: MAGE.Event, userUri: URL) async -> Bool {
        canUpdateImportantReturnValue
    }
    
    func avatarChosen(user: MAGE.UserModel, imageData: Data) {
        
    }
    
    func handleAvatarResponse(response: [AnyHashable : Any], user: MAGE.UserModel, imageData: Data, image: UIImage) {
        
    }
    
    
}
