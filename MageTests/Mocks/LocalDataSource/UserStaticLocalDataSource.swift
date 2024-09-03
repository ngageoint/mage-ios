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
    var handleUserResponseResponse: [AnyHashable: Any]?
    func handleUserResponse(response: [AnyHashable : Any]) async -> MAGE.UserModel? {
        handleUserResponseResponse = response
        return nil
    }
    
    var currentUserUri: URL?
    var users: [UserModel] = []
    var canUpdateImportantReturnValues: [NSNumber: [UserModel]] = [:]
    
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
    
    var subjectMap: [URL : CurrentValueSubject<UserModel, Never>] = [:]
    
    func observeUser(userUri: URL?) -> AnyPublisher<MAGE.UserModel, Never>? {
        guard let userUri = userUri else { return nil }
        if let user = users.first(where: { model in
            model.userId == userUri
        }) {
            let subject = CurrentValueSubject<UserModel, Never>(user)
            subjectMap[userUri] = subject
            return AnyPublisher(subject)
        } else {
            return nil
        }
    }
    
    func updateUser(userUri: URL, model: UserModel) {
        users.removeAll { model in
            model.userId == userUri
        }
        users.append(model)
        if let subject = subjectMap[userUri] {
            subject.send(model)
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
    
    func canUserUpdateImportant(event: EventModel, userUri: URL) async -> Bool {
        guard let eventId = event.remoteId else { return false }
        return canUpdateImportantReturnValues[eventId]?.first(where: { model in
            model.userId == userUri
        }) != nil
    }
    
    var avatarChosenUser: UserModel?
    var avatarChosenImageData: Data?
    
    func avatarChosen(user: MAGE.UserModel, imageData: Data) {
        avatarChosenUser = user
        self.avatarChosenImageData = imageData
    }
    
    var avatarResponse: [AnyHashable : Any]?
    var avatarResponseUser: UserModel?
    var avatarResponseImageData: Data?
    var avatarResponseImage: UIImage?
    func handleAvatarResponse(response: [AnyHashable : Any], user: MAGE.UserModel, imageData: Data, image: UIImage) async -> Bool {
        avatarResponse = response
        avatarResponseUser = user
        avatarResponseImageData = imageData
        avatarResponseImage = image
        return true
    }
    
    
}
