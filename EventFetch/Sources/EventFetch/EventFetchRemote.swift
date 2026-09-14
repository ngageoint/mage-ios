import Foundation
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public protocol EventFetchRemote: FetchRemoteDataSource where DTO == EventDTO {
    
}

public final class EventFetchRemoteImpl: EventFetchRemote {
    public typealias DTO = EventDTO
    
    let url: URL
    let session: TokenAPISession
    
    public init(
        url: URL,
        session: TokenAPISession
    ) {
        self.url = url
        self.session = session
    }
    
    public func fetch(
        urlRequest: URLRequest? = nil,
        progress: @escaping OperationProgressHandler
    ) async throws -> [DTO] {
        let urlRequestConvertible = EventFetchRouter(
            baseURL: url,
            endpoint: .fetchEvents
        )
        do {
            let dto = try await session.session
                .request(urlRequest ?? urlRequestConvertible)
                .downloadProgress { download in
                    progress(
                        OperationProgress(
                            completed: Int64(download.completedUnitCount),
                            total: Int64(download.totalUnitCount)
                        )
                    )
                }
                .validate(session.validateResponse())
                .serializingDecodable([DTO].self)
                .value
            return dto
        } catch {
            EventFetchPackage.logger.error("Error fetching events: \(error)")
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
