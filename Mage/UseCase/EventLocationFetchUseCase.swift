// 
//     
//  EventLocationFetchUseCase.swift
//  MAGE
//
//

import Foundation
import FetchOperation
import ServerDTO
import Pipeline
import LocationFetch
import UserFetch
import User
import UseCaseFactory

public final class EventLocationFetchUseCase: UseCase, Sendable {
    let repository: AnyFetchRepository<LocationFetchRequest, LocationRepositoryFetchResult>
    let userRepository: UserRepository
    
    init(
        repository: AnyFetchRepository<LocationFetchRequest, LocationRepositoryFetchResult>,
        userRepository: UserRepository,
    ) {
        self.repository = repository
        self.userRepository = userRepository
    }
    
    func execute(
        eventID: EventID?,
        currentUserID: UserID?
    ) async throws {
        guard let eventID,
              let currentUserID
        else {
            return
        }
        
        let operation = repository.startFetch(
            LocationFetchRequest(eventID: eventID, currentUserID: currentUserID)
        )

        let output = try await operation.value()
        LocationFetchPackage.logger.info(
            "Fetched Locations - Inserts: \(output.inserts); Updates: \(output.updates)"
        )
        if let missingUserIDs = output.missingUserIDs,
           !missingUserIDs.isEmpty
        {
            for userID in missingUserIDs {
                _ = try? await userRepository.refreshUser(userID: userID)
            }
            LocationFetchPackage.logger.info("There were \(missingUserIDs.count) missing user IDs. Fetching users for event: \(eventID)")
        }
    }
}
