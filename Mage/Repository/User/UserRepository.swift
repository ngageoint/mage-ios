//
//  UserRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import CLLocationCoordinate2DExtensions

private struct UserRepositoryProviderKey: InjectionKey {
    static var currentValue: UserRepository = UserRepository()
}

extension InjectedValues {
    var userRepository: UserRepository {
        get { Self[UserRepositoryProviderKey.self] }
        set { Self[UserRepositoryProviderKey.self] = newValue }
    }
}

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

class UserRepository: ObservableObject {
    @Injected(\.eventRepository)
    var eventRepository: EventRepository
    
    @Injected(\.userLocalDataSource)
    var localDataSource: UserLocalDataSource
    
    @Injected(\.userRemoteDataSource)
    var remoteDataSource: UserRemoteDataSource

    func getUser(userUri: URL?) async -> UserModel? {
        await localDataSource.getUser(userUri: userUri)
    }
    
    func getCurrentUser() -> UserModel? {
        localDataSource.getCurrentUser()
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        localDataSource.observeUser(userUri: userUri)
    }
    
    func getUser(remoteId: String) -> UserModel? {
        localDataSource.getUser(remoteId: remoteId)
    }
    
    func users(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        localDataSource.users(paginatedBy: paginator)
    }
    
    func canUserUpdateImportant(
        eventId: NSNumber,
        userUri: URL
    ) async -> Bool {
        if let event = eventRepository.getEvent(eventId: eventId) {
            return await localDataSource.canUserUpdateImportant(event: event, userUri: userUri)
        }
        return false
    }
    
    func avatarChosen(user: UserModel, image: UIImage) async {
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            localDataSource.avatarChosen(user: user, imageData: imageData)
            let response = await remoteDataSource.uploadAvatar(user: user, imageData: imageData)
            localDataSource.handleAvatarResponse(response: response, user: user, imageData: imageData, image: image)
        }
    }
}
