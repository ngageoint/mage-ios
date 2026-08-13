// 
//     
//  SettingsRepository.swift
//  Settings
//
// 


import Foundation
import APIRouter

public protocol SettingsRepository : Sendable{
    func getSettings() async -> SettingsModel?
    func getMapSearchSession() async -> TokenAPISession?
    func observeSettings() -> AsyncStream<SettingsModel>
}

final class SettingsRepositoryImpl: SettingsRepository {
    let session: TokenAPISession
    let localDataSource: SettingsLocalDataSource
    
    init(
        session: TokenAPISession,
        localDataSource: SettingsLocalDataSource
    ) {
        self.session = session
        self.localDataSource = localDataSource
    }
    
    func getMapSearchSession() async -> TokenAPISession? {
        guard let settings = await getSettings() else { return nil }
        
        if let mapSearchUrlString = settings.mapSearchUrl,
            let mapSearchUrl = URL(
                string: mapSearchUrlString
            ), let host = mapSearchUrl.host()
        {
            session.addTrustedHost(host)
            SettingsPackage.logger.debug("Map search url host \(host)")
        }
        
        return session
    }

    func getSettings() async -> SettingsModel? {
        do {
            return try await localDataSource.getSettings()
        } catch {
            SettingsPackage.logger.error("Error getting settings \(error)")
        }
        return nil
    }
    
    func observeSettings() -> AsyncStream<SettingsModel> {
        return localDataSource.observeSettings()
    }
}
