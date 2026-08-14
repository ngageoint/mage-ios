//
//  UserFetchRemote.swift
//  UserFetch
//
//  Created by Daniel Barela on 8/4/26.
//

import Foundation
import FetchOperation
import ServerDTO
import APIRouter
import User
import Pipeline

public final class UserFetchRemote: FetchRemoteDataSource {

    public typealias DTO = UserDTO
    
    let url: URL
    let session: TokenAPISession
    let eventID: EventID
    
    public init(
        url: URL,
        session: TokenAPISession,
        eventID: EventID
    ) {
        self.url = url
        self.session = session
        self.eventID = eventID
    }
    
    public func fetch(
        urlRequest: URLRequest? = nil,
        progress: @escaping OperationProgressHandler
    ) async throws -> [UserDTO] {
        let request = UserRouter(
            baseURL: url,
            endpoint: .fetchEventUsers(eventId: eventID.rawValue)
        )
        
        do {
            let dto = try await session.session
                .request(request)
                .downloadProgress { download in
                    progress(
                        OperationProgress(
                            completed: download.completedUnitCount,
                            total: download.totalUnitCount
                        )
                    )
                }
                .validate(session.validateResponse())
                .serializingDecodable([UserDTO].self)
                .value
            return dto
        } catch {
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
