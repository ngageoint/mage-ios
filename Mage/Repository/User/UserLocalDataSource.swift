//
//  UserLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import Kingfisher

private struct UserLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: UserLocalDataSource = UserCoreDataDataSource()
}

extension InjectedValues {
    var userLocalDataSource: UserLocalDataSource {
        get { Self[UserLocalDataSourceProviderKey.self] }
        set { Self[UserLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol UserLocalDataSource {
    func getUser(userUri: URL?) async -> UserModel?
    func getCurrentUser() -> UserModel?
    func observeUser(
        userUri: URL?
    ) -> AnyPublisher<UserModel, Never>?
    
    func getUser(remoteId: String) -> UserModel?
    func users(
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
    func canUserUpdateImportant(
        event: Event,
        userUri: URL
    ) async -> Bool
    
    func avatarChosen(user: UserModel, imageData: Data)
    func handleAvatarResponse(response: [AnyHashable: Any], user: UserModel, imageData: Data, image: UIImage)
}

struct UserModelPage {
    var list: [URIItem]
    var next: Int?
    var currentHeader: String?
}

class UserCoreDataDataSource: CoreDataDataSource, UserLocalDataSource, ObservableObject {
    private lazy var context: NSManagedObjectContext = {
        NSManagedObjectContext.mr_default()
    }()
    
    private func getUserNSManagedObject(userUri: URL) async -> User? {
        let context = context
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                return try? context.existingObject(with: id) as? User
            }
            return nil
        }
    }
    
    func getUser(userUri: URL?) async -> UserModel? {
        guard let userUri = userUri else {
            return nil
        }
        let context = context
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                return (try? context.existingObject(with: id) as? User).map { user in
                    UserModel(user: user)
                }
            }
            return nil
        }
    }
    
    func getCurrentUser() -> UserModel? {
        User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()).map { user in
            UserModel(user: user)
        }
    }
    
    func getUser(remoteId: String) -> UserModel? {
        return context.performAndWait {
            return context.fetchFirst(User.self, key: "remoteId", value: remoteId).map { user in
                UserModel(user: user)
            }
        }
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        guard let userUri = userUri else {
            return nil
        }
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                if let user = try? context.existingObject(with: id) as? User {
                    return publisher(for: user, in: context)
                        .prepend(user)
                        .map({ user in
                            return UserModel(user: user)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
    
    func users(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        return users(
            at: nil,
            currentHeader: nil,
            paginatedBy: paginator
        )
        .map(\.list)
        .eraseToAnyPublisher()
    }
    
    func users(
        at page: Page?,
        currentHeader: String?,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<URIModelPage, Error> {
        return users(
            at: page,
            currentHeader: currentHeader
        )
        .map { result -> AnyPublisher<URIModelPage, Error> in
            if let paginator = paginator, let next = result.next {
                return self.users(
                    at: next,
                    currentHeader: result.currentHeader,
                    paginatedBy: paginator
                )
                .wait(untilOutputFrom: paginator)
                .retry(.max)
                .prepend(result)
                .eraseToAnyPublisher()
            } else {
                return Just(result)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func users(
        at page: Page?,
        currentHeader: String?
    ) -> AnyPublisher<URIModelPage, Error> {

        let request = User.fetchRequest()
        let predicates: [NSPredicate] = [NSPredicate(value: true)]
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.predicate = predicate

        request.includesSubentities = false
        request.includesPropertyValues = false
        request.fetchLimit = 100
        request.fetchOffset = (page ?? 0) * request.fetchLimit
        request.sortDescriptors = [NSSortDescriptor(key: "location.timestamp", ascending: false)]
        let previousHeader: String? = currentHeader
        var users: [URIItem] = []
        context.performAndWait {
            if let fetched = context.fetch(request: request) {

                users = fetched.flatMap { user in
                    return [URIItem.listItem(user.objectID.uriRepresentation())]
                }
            }
        }

        let page: URIModelPage = URIModelPage(
            list: users, 
            next: (page ?? 0) + 1,
            currentHeader: previousHeader
        )

        return Just(page)
            .setFailureType(to: Error.self)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func canUserUpdateImportant(
        event: Event,
        userUri: URL
    ) async -> Bool {
        let user = await getUserNSManagedObject(userUri: userUri)
                
        if let userRemoteId = user?.remoteId,
           let acl = event.acl,
           let userAcl = acl[userRemoteId] as? [String : Any],
           let userPermissions = userAcl[PermissionsKey.permissions.key] as? [String] {
            if (userPermissions.contains(PermissionsKey.update.key)) {
                return true
            }
        }
        
        // if the user has UPDATE_EVENT permission
        if let role = user?.role, let rolePermissions = role.permissions {
            if rolePermissions.contains(PermissionsKey.UPDATE_EVENT.key) {
                return true
            }
        }

        return false
    }
    
    func avatarChosen(user: UserModel, imageData: Data) {
        let documentsDirectories: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if (documentsDirectories.count != 0 && FileManager.default.fileExists(atPath: documentsDirectories[0])) {
            let userAvatarPath = "\(documentsDirectories[0])/userAvatars/\(user.remoteId ?? "temp")";
            do {
                try imageData.write(to: URL(fileURLWithPath: userAvatarPath))
            } catch {
                print("Could not write image file to destination")
            }
        }
    }
    
    func handleAvatarResponse(response: [AnyHashable : Any], user: UserModel, imageData: Data, image: UIImage) {
        // store the image data for the updated avatar in the cache here
        guard let userUri = user.userId else {
            return
        }
        let context = context
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                if let user = try? context.existingObject(with: id) as? User {
                    user.update(json: response, context: context)
                    if let cacheAvatarUrl = user.cacheAvatarUrl,
                        let url = URL(string: cacheAvatarUrl)
                    {
                        print("XXX caching for url \(url.absoluteString)")
                        KingfisherManager.shared.cache.store(image, original:imageData, forKey: url.absoluteString) {_ in
                            try? context.save()
                        }
                    }
                }
            }
        }
    }
}
