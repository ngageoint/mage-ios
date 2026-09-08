import Foundation
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public protocol StaticLayerFetchRemote: FetchRemoteDataSource where DTO == StaticLayerFeatureCollectionDTO {
    
}

public final class StaticLayerFetchRemoteImpl: StaticLayerFetchRemote {
    
    public typealias DTO = StaticLayerFeatureCollectionDTO
    
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
        guard let urlRequest else { return [] }
        do {
            let dto = try await session.session
                .request(urlRequest)
                .downloadProgress { download in
                    progress(
                        OperationProgress(
                            completed: download.completedUnitCount,
                            total: download.totalUnitCount
                        )
                    )
                }
                .validate(session.validateResponse())
                .serializingDecodable(DTO.self)
                .value
            return [dto]
        } catch {
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
