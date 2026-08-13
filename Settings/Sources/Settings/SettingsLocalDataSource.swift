// 
//     
//  SettingsLocalDataSource.swift
//  Settings
//
// 


import Foundation
import Persistence
import CoreData
import ServerDTO

protocol SettingsLocalDataSource: Sendable {
    func getSettings() async throws -> SettingsModel?
}

final class SettingsLocalDataSourceImpl: SettingsLocalDataSource {
    let persistence: PersistenceProtocol
        
    init(persistence: PersistenceProtocol) {
        self.persistence = persistence
    }
    
    func getSettings() async throws -> SettingsModel? {
        return try await persistence.read { context in
            return (try context.fetchFirst(Settings.self)).map { settings in
                SettingsModel(settings: settings)
            }
        }
    }
}
