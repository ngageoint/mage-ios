//
//  LocationFetchRemote.swift
//  LocationFetch
//

import Foundation
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public final class LocationFetchRemote: FetchRemoteDataSource {
    
    public typealias DTO = UserLocationDTO
    
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
    ) async throws -> [UserLocationDTO] {
        let urlRequestConvertible = LocationFetchRouter(
            baseURL: url,
            endpoint: .fetchLocations(
                eventId: eventID.rawValue,
                lastLocationDate: nil
            )
        )
        do {
            let dto = try await session.session
                .request(urlRequest ?? urlRequestConvertible)
                .downloadProgress { download in
                    progress(
                        OperationProgress(
                            completed: download.completedUnitCount,
                            total: download.totalUnitCount
                        )
                    )
                }
                .validate(session.validateResponse())
                .serializingDecodable([UserLocationDTO].self)
                .value
            return dto
        } catch {
            LocationFetchPackage.logger.error("Error fetching locations: \(error)")
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
