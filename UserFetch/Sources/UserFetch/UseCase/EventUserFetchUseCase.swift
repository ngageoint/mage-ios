// 
//     
//  EventUserFetchUseCase.swift
//  UserFetch
//
// 


import Foundation
import FetchOperation
import ServerDTO
import Pipeline

public final class EventUserFetchUseCase: Sendable {
    let userFetchRepository: AnyFetchRepository<UserFetchRequest, [UserDTO]>
    
    public init(userFetchRepository: AnyFetchRepository<UserFetchRequest, [UserDTO]>) {
        self.userFetchRepository = userFetchRepository
    }
    
    public func execute(eventID: EventID?) async throws {
        guard let eventID
        else {
            return
        }
                
        let operation = userFetchRepository.startFetch(
            UserFetchRequest(eventID: eventID)
        )
        
        let finalValue = try await operation.value()
        
        UserFetchPackage.logger.info("Fetched Users: \(finalValue.count) users")
    }
}
