// 
//     
//  ObserveSettingsUseCaseTests.swift
//  MAGE
//
// 

import Testing
import Settings
import Persistence
import CoreData
import APIRouter
import TestUtilities
import ServerDTO

@testable import MAGE

extension CoreDataTests {
    @MainActor
    struct ObserveSettingsUseCaseTests {
        
        @Test(
            .persistence()
        )
        func `test observe with nothing initially in the database`() async throws {
            _ = try await PersistenceContext.current!.persistence.write { context in
                for settings in (try? context.fetchObjects(Settings.self)) ?? [] {
                    context.delete(settings)
                }
            }
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Settings.self,
                    0
                )
            
            let settingsRepository = SettingsRepositoryFactory.createRepository(
                url: URL(string:"https://magetest")!,
                session: TokenAPISessionImpl(baseURL: URL(string:"https://magetest")!, loginType: "online"),
                persistence: PersistenceContext.current!.persistence
            )
            
            let observeUseCase = ObserveSettingsUseCaseImpl(
                repository: settingsRepository
            )
            var settingsModel: SettingsModel?

            let stream = observeUseCase.execute()
            
            let observeSettingsTask = Task { @MainActor in
                for await settings in observeUseCase.execute() {
                    settingsModel = settings
                }
            }
            
            _ = try await PersistenceContext.current!.persistence.write { context in
                let settings = Settings(context: context)
                settings.mapSearchUrl = "https://example.com"
                settings.mapSearchType = ServerDTO.MapSearchType.nominatim
            }
            
            await TestUtilities.waitForCondition({
                settingsModel != nil
            }, timeout: 1.0, message: "Settings model was not found")
            
            #expect(settingsModel?.mapSearchUrl == "https://example.com")
            #expect(settingsModel?.mapSearchType == .nominatim)
        }
        
    }
}
