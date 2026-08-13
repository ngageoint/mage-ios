// 
//     
//  SettingsFetchLocalsaveResult.swift
//  SettingsFetch
//
// 


import ServerDTO
import Persistence
import CoreData
import FetchOperation
import Pipeline

struct SettingsFetchLocalsaveResult: Sendable {
    var saved: Int
}

final class SettingsFetchLocal: FetchLocalDataSource {
    typealias DTO = MapSettingsDTO
    typealias SaveResult = SettingsFetchLocalsaveResult
    
    let persistence: PersistenceProtocol
    
    init(persistence: PersistenceProtocol) {
        self.persistence = persistence
    }
    
    func save(
        _ dto: [MapSettingsDTO],
        progress: OperationProgressHandler
    ) async throws -> SettingsFetchLocalsaveResult {
        if let response = dto.first {
            let result = try await persistence.write { context in
                let settings: Settings = try Self.getOrCreateSettings(in: context)
                settings.mapSearchUrl = response.mobileNominatimUrl
                settings.mapSearchType = response.mobileSearchType ?? .none
                
                return 1
            }
            return SettingsFetchLocalsaveResult(saved: result.blockReturn ?? 0)
        }
        return SettingsFetchLocalsaveResult(saved: 0)
    }
    
    nonisolated
    private static func getOrCreateSettings(in context: NSManagedObjectContext) throws -> Settings {
        if let settings = try context.fetchFirst(Settings.self) {
            return settings
        } else {
            let settings = Settings(context: context)
            try context.obtainPermanentIDs(for: [settings])
            return settings
        }
    }
}
