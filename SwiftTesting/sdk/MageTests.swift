// 
//     
//  MageTests.swift
//  MAGE
//
// 

import Testing
import TestUtilities
import Alamofire
import Persistence
import Settings
import ServerDTO
import User

@testable import MAGE

extension CoreDataTests {
    struct MageTests {
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/settings/map",
                responseJSON: [
                    "mobileNominatimUrl": "https://example.com",
                    "mobileSearchType": "NOMINATIM"
                ]
            )
        )
        func `test settings get fetched`() async throws {
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
            
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            let mage = Mage.singleton
            await mage.fetchSettings()
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Settings.self,
                    1
                )
            try await PersistenceContext.current!.persistence.read { context in
                let settings = try #require(try context.fetchFirst(Settings.self))
                #expect(settings.mapSearchUrl == "https://example.com")
                #expect(
                    settings.mapSearchType == ServerDTO.MapSearchType.nominatim
                )
            }
            
            let settingsRepository = await SettingsRepositoryFactory.createRepository(
                url: DependencyContainer.shared.url!,
                session: DependencyContainer.shared.session!,
                persistence: DependencyContainer.shared.persistence!
            )

            let settingsModel = try #require(await settingsRepository.getSettings())
            #expect(settingsModel.mapSearchUrl == "https://example.com")
            #expect(settingsModel.mapSearchType == .nominatim)
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/users",
                responseFile: "eventUsers.json"
            )
        )
        func `test users get fetched for the event`() async throws {
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(User.self)) ?? [] {
                    context.delete(user)
                }
            }
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    0
                )
            
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            let mage = Mage.singleton
            await mage.fetchUsers()
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    3
                )
            let userModel = try await PersistenceContext.current!.persistence.read { context in
                let user = try #require(try context.fetchFirst(User.self, key: "remoteId", value: "userabc"))
                #expect(user.name == "username")
                return UserModel(from: user)
            }
            #expect(userModel.name == "username")
        }
        
    }
}
