import Foundation
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public protocol LayerFetchRemote: FetchRemoteDataSource where DTO == MapLayerDTO {
    
}

public final class LayerFetchRemoteImpl: LayerFetchRemote {
    
    public typealias DTO = MapLayerDTO
    
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
        let sessionRequest = session.session
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
        
        do {
            let dto = try await sessionRequest
                .serializingDecodable([DTO].self)
                .value
            return dto
        } catch {
            let string = try? await sessionRequest.serializingString().value
            LayerFetchPackage.logger.error("Could not deserialize result; string value is \(string ?? "")")
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
