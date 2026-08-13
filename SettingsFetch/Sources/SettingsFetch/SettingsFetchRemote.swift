// 
//     
//  SettingsFetchRemote.swift
//  SettingsFetch
//
// 


import Foundation
import APIRouter
import ServerDTO
import FetchOperation
import Pipeline

final class SettingsFetchRemote: FetchRemoteDataSource, Sendable {
    let url: URL
    let session: TokenAPISession
    
    required init(url: URL, session: TokenAPISession) {
        self.url = url
        self.session = session
    }
    
    func fetch(
        urlRequest: URLRequest? = nil,
        progress: @escaping OperationProgressHandler
    ) async throws -> [MapSettingsDTO] {
        let request = SettingsRouter(baseURL: url, endpoint: .fetchMapSettings)
        
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
                .serializingDecodable(MapSettingsDTO.self)
                .value
            return [dto]
        } catch {
            throw error.asAFError?.underlyingError ?? error
        }
    }

}
