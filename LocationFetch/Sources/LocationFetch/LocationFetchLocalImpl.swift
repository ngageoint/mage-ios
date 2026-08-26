//
//  LocationFetchLocal.swift
//  MAGE
//
//

import Foundation
import Persistence
import FetchOperation
import ServerDTO
import User
import Location
import Pipeline

public final class LocationFetchLocalImpl: LocationFetchLocal {
    public typealias DTO = UserLocationDTO
    public typealias SaveResult = LocationSaveResult
    internal let chunkSize = 250
    let persistence: PersistenceProtocol
    let currentUserID: UserID
    
    public init(
        persistence: PersistenceProtocol,
        currentUserID: UserID
    ) {
        self.persistence = persistence
        self.currentUserID = currentUserID
    }
    
    public func getLastLocationDate(eventId: Int) async -> Date? {
        return await persistence.read { context in
            let location = try? context.fetchFirst(
                Location.self,
                sortBy: [NSSortDescriptor(key: LocationKey.timestamp.key, ascending: false)],
                predicate: NSPredicate(
                    format: "\(LocationKey.eventId.key) == %@", NSNumber(value: eventId))
            )
            
            return location?.timestamp
        }
    }
    
    public func save(
        _ dto: [UserLocationDTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        let totalCount: Int64 = Int64(dto.count)
        var handled: Int = 0
        let chunks = dto.chunked(into: chunkSize)
        
        var saveResult = LocationSaveResult.empty
        
        for chunk in chunks {
            if let chunkSaveResult = try await handleChunk(chunk: chunk) {
                saveResult.combine(with: chunkSaveResult)
                handled += chunkSaveResult.ignored + chunkSaveResult.deleted + chunkSaveResult.inserted + chunkSaveResult.updated
            }
            
            if handled % 50 == 0 {
                try Task.checkCancellation()
                progress(
                    OperationProgress(
                        completed: Int64(handled),
                        total: totalCount
                    )
                )
            }
        }
        progress(
            OperationProgress(
                completed: Int64(handled),
                total: totalCount
            )
        )
        return saveResult
    }
    
    func handleChunk(chunk: [UserLocationDTO]) async throws -> LocationSaveResult? {
        let persistenceResult = try await persistence.write { context in
            var saveResult = LocationSaveResult.empty
            
            var userIds: [String] = []
            
            for user in chunk {
                if let userId = user.id {
                    userIds.append(userId)
                }
            }
            
            let fetchRequest = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "(\(UserKey.remoteId.key) IN %@)", userIds)
            let usersMatchingIDs: [User] = (try? context.fetch(fetchRequest)) ?? []
            var userIdMap: [String : User] = [:]
            for user in usersMatchingIDs {
                if let remoteId = user.remoteId {
                    userIdMap[remoteId] = user
                }
            }
            for userJson in chunk {
                // pull from query map
                guard let userId = userJson.id,
                      let locations = userJson.locations
                else {
                    continue
                }
                // Do not store my own location
                if self.currentUserID == userId {
                    // need to report that we handled this user even if we did not save it
                    saveResult.ignored += 1
                    continue
                }
                if let user = userIdMap[userId] {
                    if let location = user.location {
                        // already exists in core data, lets update the object we have
                        let locationDTO = locations[0]
                        location.populate(dto: locationDTO)
                        
                        saveResult.updated += 1
                    } else {
                        // not in core data yet need to create a new managed object
                        let location = Location(context: context)
                        try? context.obtainPermanentIDs(for: [location])
                        if let locationDTO = locations.first {
                            location.populate(dto: locationDTO)
                            user.location = location
                        }
                        saveResult.inserted += 1
                    }
                    
                    // this could happen if we pulled the teams and know this user belongs on a team
                    // but did not pull the user information because the bulk user pull failed
                    if !user.isPopulated {
                        saveResult.missingUserIds.insert(userId)
                    }
                } else {
                    if (locations.count != 0) {
                        LocationFetchPackage.logger.info(
                            "Could not find user for id \(userId)"
                        )
                        saveResult.missingUserIds.insert(userId)
                        
                        let user = User(context: context)
                        user.remoteId = userId
                        
                        if let userFromJson = userJson.user {
                            user.username = userFromJson.username
                            user.email = userFromJson.email
                            user.name = userFromJson.displayName
                            if let phones = userFromJson.phones,
                               phones.count > 0
                            {
                                user.phone = phones[0].number
                            }
                            user.iconUrl = userFromJson.iconUrl
                            if let icon = userFromJson.icon {
                                user.iconText = icon.text
                                user.iconColor = icon.color
                            }
                            user.avatarUrl = userFromJson.avatarUrl
                            user.recentEventIds = userFromJson.recentEventIds?.map({ int in
                                NSNumber(value: int)
                            })
                            
                            user.createdAt = userFromJson.createdAt
                            user.lastUpdated = userFromJson.lastUpdated
                        }
                        let location = Location(context: context)
                        try? context.obtainPermanentIDs(for: [location])
                        if let locationDTO = locations.first {
                            location.populate(dto: locationDTO)
                            user.location = location
                        }
                        try? context.obtainPermanentIDs(for: [user])
                        saveResult.inserted += 1
                    }
                }
            }
            return saveResult
        }
        return persistenceResult.blockReturn
    }
    
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
