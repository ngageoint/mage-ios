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
    func observeSettings() -> AsyncStream<SettingsModel>
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

    func observeSettings() -> AsyncStream<SettingsModel> {
        
        return AsyncStream { continuation in
            Task { @MainActor in
                do {
                    let fetchChanges: FetchedResultsChangesAsyncStream<SettingsModel> = try persistence.makeFetchedChangesStream(
                        request: {
                            let request = Settings.fetchRequest()
                            request.sortDescriptors = [NSSortDescriptor(keyPath: \Settings.mapSearchUrl, ascending: true)]
                            return request
                        },
                        sectionNameKeyPath: nil
                    )
                    
                    let task = Task { @MainActor in
                        for await value in fetchChanges.stream {
                            switch (value) {
                                
                            case .initial(let states):
                                guard let state = states.first else {
                                    continue
                                }
                                continuation.yield(state)
                            case .insert(_, let state):
                                continuation.yield(state)
                            case .delete(_, _):
                                break
                            case .update(_, let state):
                                continuation.yield(state)
                            case .move(_, _):
                                break
                            }
                        }
                        continuation.finish()
                    }
                    
                    continuation.onTermination = { _ in
                        task.cancel()
                        // observer retained until stream terminates
                        _ = fetchChanges
                    }
                } catch {
                    return
                }
            }
        }
    }
}
