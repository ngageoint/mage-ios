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

private struct ManagedObjectContextProviderKey: InjectionKey {
    static var currentValue: NSManagedObjectContext? = nil
}

extension InjectedValues {
    var nsManagedObjectContext: NSManagedObjectContext? {
        get { Self[ManagedObjectContextProviderKey.self] }
        set { Self[ManagedObjectContextProviderKey.self] = newValue }
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
        event: EventModel,
        userUri: URL
    ) async -> Bool
    
    func avatarChosen(user: UserModel, imageData: Data)
    func handleAvatarResponse(response: [AnyHashable: Any], user: UserModel, imageData: Data, image: UIImage) async -> Bool
    func handleUserResponse(response: [AnyHashable: Any]) async -> UserModel?
}

struct UserModelPage {
    var list: [URIItem]
    var next: Int?
    var currentHeader: String?
}

class UserCoreDataDataSource: CoreDataDataSource<User>, UserLocalDataSource, ObservableObject {
    @Injected(\.roleLocalDataSource)
    var roleLocalDataSource: RoleLocalDataSource
    
    private func getUserNSManagedObject(remoteId: String, context: NSManagedObjectContext) async -> User? {
        return await context.perform {
            return context.fetchFirst(User.self, key: UserKey.remoteId.key, value: remoteId)
        }
    }
    
    private func getUserNSManagedObject(userUri: URL) async -> User? {
        guard let context = context else { return nil }
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
        guard let context = context else { return nil }
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
        guard let context = context else { return nil }
        return User.fetchCurrentUser(context: context).map { user in
            UserModel(user: user)
        }
    }
    
    func getUser(remoteId: String) -> UserModel? {
        guard let context = context else { return nil }
        return context.performAndWait {
            return context.fetchFirst(User.self, key: "remoteId", value: remoteId).map { user in
                UserModel(user: user)
            }
        }
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        guard let context = context else { return nil }
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
    
    override func getFetchRequest(parameters: [AnyHashable: Any]? = nil) -> NSFetchRequest<User> {
        let request = User.fetchRequest()
        let predicates: [NSPredicate] = [NSPredicate(value: true)]
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.predicate = predicate

        request.includesSubentities = false
        request.includesPropertyValues = false
        request.sortDescriptors = [NSSortDescriptor(key: "location.timestamp", ascending: false)]
        return request
    }

    func users(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        return uris(
            at: nil,
            currentHeader: nil,
            paginatedBy: paginator
        )
        .map(\.list)
        .eraseToAnyPublisher()
    }
 
    func canUserUpdateImportant(
        event: EventModel,
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
        guard let remoteId = user.remoteId, let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let avatarsDirectory = documentsDirectory.appendingPathComponent("userAvatars")
        do {
            try FileManager.default.createDirectory(at: avatarsDirectory, withIntermediateDirectories: true, attributes: [.protectionKey : FileProtectionType.complete])
        }
        catch {
            MageLogger.misc.error("error creating directory \(avatarsDirectory) to save user avatars", error)
            return
        }
        let userAvatarPath = avatarsDirectory.appendingPathComponent(remoteId)
        do {
            try imageData.write(to: userAvatarPath)
        } catch {
            MageLogger.misc.error("Could not write image file to destination \(error)")
        }
    }
    
    func handleAvatarResponse(response: [AnyHashable : Any], user: UserModel, imageData: Data, image: UIImage) async -> Bool {
        // store the image data for the updated avatar in the cache here
        guard let userUri = user.userId else {
            return false
        }
        guard let context = context else { return false }
        return await withCheckedContinuation { continuation in
            context.perform {
                if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri),
                   let user = try? context.existingObject(with: id) as? User
                {
                    user.update(json: response, context: context)
                    if let cacheAvatarUrl = user.cacheAvatarUrl,
                       let url = URL(string: cacheAvatarUrl)
                    {
                        KingfisherManager.shared.cache.store(image, original:imageData, forKey: url.absoluteString) { result in
                            context.perform {
                                do {
                                    try context.save()
                                    continuation.resume(returning: true)
                                    return
                                } catch {
                                    MageLogger.misc.error("error saving user after avatar save \(error)")
                                }
                                continuation.resume(returning: false)
                            }
                        }
                    } else {
                        continuation.resume(returning: false)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func handleUserResponse(response: [AnyHashable: Any]) async -> UserModel? {
        guard let context = context,
              let userId = response["id"] as? String
        else {
            return nil
        }
        
        return await withCheckedContinuation { [weak self] continuation in
            context.perform {
                var user: User = {
                    if let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: userId) {
                        return user
                    } else {
                        let user = User(context: context)
                        try? context.obtainPermanentIDs(for: [user])
                        return user
                    }
                }()
                user.remoteId = response[UserKey.id.key] as? String
                user.username = response[UserKey.username.key] as? String
                user.email = response[UserKey.email.key] as? String
                user.name = response[UserKey.displayName.key] as? String
                if let phones = response[UserKey.phones.key] as? [[AnyHashable : Any]], phones.count > 0 {
                    user.phone = phones[0][UserPhoneKey.number.key] as? String
                }
                user.iconUrl = response[UserKey.iconUrl.key] as? String
                if let icon = response[UserKey.icon.key] as? [AnyHashable : Any] {
                    user.iconText = icon[UserIconKey.text.key] as? String
                    user.iconColor = icon[UserIconKey.color.key] as? String
                }
                user.avatarUrl = response[UserKey.avatarUrl.key] as? String
                user.recentEventIds = response[UserKey.recentEventIds.key] as? [NSNumber]
                
                let dateFormat = DateFormatter();
                dateFormat.timeZone = TimeZone(secondsFromGMT: 0);
                dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                let posix = Locale(identifier: "en_US_POSIX");
                dateFormat.locale = posix;
                
                if let createdAtString = response[UserKey.createdAt.key] as? String {
                    user.createdAt = dateFormat.date(from: createdAtString)
                }
                
                if let lastUpdatedString = response[UserKey.lastUpdated.key] as? String {
                    user.lastUpdated = dateFormat.date(from: lastUpdatedString)
                }
                // go pull their icon and avatar if they got one using the image cache which will decide if we need to pull
                self?.prefetchIconAndAvatar(iconUrl: user.cacheIconUrl, avatarUrl: user.cacheAvatarUrl)
                
                if let userRole = response[UserKey.role.key] as? [AnyHashable : Any] {
                    // TODO: is this the correct place for this?
                    self?.roleLocalDataSource.addUserToRole(
                        roleJson: userRole,
                        user: user,
                        context: context
                    )
                }
                try? context.save()
                
                continuation.resume(returning: UserModel(user: user))
            }
        }
    }
    
    func prefetchIconAndAvatar(iconUrl: String?, avatarUrl: String?) {
        if let cacheIconUrl = iconUrl, let url = URL(string: cacheIconUrl) {
            let prefetcher = ImagePrefetcher(urls: [url], options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .diskCacheExpiration(.never)
            ]) {
                skippedResources, failedResources, completedResources in
            }
            prefetcher.start()
        }
        if let cacheAvatarUrl = avatarUrl, let url = URL(string: cacheAvatarUrl) {
            MageLogger.misc.debug("caching avatar \(url)")
            let prefetcher = ImagePrefetcher(urls: [url], options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            ]) {
                skippedResources, failedResources, completedResources in
            }
            prefetcher.start()
        }
    }
}
