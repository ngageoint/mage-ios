//
//  SettingsFetchRepositoryFactory.swift
//  SettingsFetch
//
//  Created by Daniel Barela on 8/12/26.
//

import APIRouter
import Persistence
import Foundation
import FetchOperation
import ServerDTO
import Pipeline

public class SettingsFetchRepositoryFactory {
    public static let SettingsFetchOperationKind = PipelineOperationKind(rawValue: "fetch settings")
    
    public static func createFetchRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<Void, [MapSettingsDTO]> {
        return AnyFetchRepository(
            FetchRepository<Void, [MapSettingsDTO]> { input in
                let pipeline = FetchPipelines.default(
                    remote: SettingsFetchRemote(
                        url: url,
                        session: session
                    ),
                    local: SettingsFetchLocal(persistence: persistence),
                    operation: SettingsFetchOperationKind
                )
                
                return pipeline.execute()
            }
        )
    }
}
