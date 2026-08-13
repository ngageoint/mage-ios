// 
//     
//  SettingsRepositoryFactory.swift
//  Settings
//
// 

import Foundation
import APIRouter
import Persistence
import Pipeline

public class SettingsRepositoryFactory {
    public static let SettingsFetchOperationKind = PipelineOperationKind(rawValue: "fetch settings")
    
    public static func createRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> SettingsRepository {
        return SettingsRepositoryImpl(
            session: session,
            localDataSource: SettingsLocalDataSourceImpl(
                persistence: persistence
            )
        )
    }
}
