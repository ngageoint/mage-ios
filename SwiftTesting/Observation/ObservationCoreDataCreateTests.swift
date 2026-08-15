// 
//     
//  ObservationCoreDataCreateTests.swift
//  MAGE
//
// 

import Testing
import Persistence
import TestUtilities
import CoreData
import Alamofire

@testable import MAGE
extension CoreDataTests {
    struct ObservationCoreDataCreateTests {
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            )
        )
        func `verify that user fetch is called when an observation with a new user is inserted`() async throws {
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            
            let json = [
                "userId": "userabc",
                "id":"observationabc"
            ]
            
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(Observation.self)) ?? [] {
                    context.delete(user)
                }
            }
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    0
                )
            
            try await PersistenceContext.current!.persistence.write { context in
                Observation
                    .create(
                        feature: json,
                        context: context
                    )
            }

            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    1
                )
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            )
        )
        func `verify that user fetch is called when an a user with no last updated is in the observation`() async throws {
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            
            let json = [
                "userId": "userabc",
                "id":"observationabc"
            ]
            
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(Observation.self)) ?? [] {
                    context.delete(user)
                }
                let newUser = User(context: context)
                newUser.remoteId = "userabc"
                try context.obtainPermanentIDs(for: [newUser])
            }
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    0
                )
            
            try await PersistenceContext.current!.persistence.write { context in
                Observation
                    .create(
                        feature: json,
                        context: context
                    )
            }
            
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    1,
                    predicate: NSPredicate(format: "username = %@", "Myself")
                )
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            )
        )
        func `verify that user fetch is called when an observation with a new user is updated`() async throws {
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            
            try await PersistenceContext.current!.persistence.write { context in
                let observation = Observation(context: context)
                observation.remoteId = "observationabc"
                observation.dirty = false
                try context.obtainPermanentIDs(for: [observation])
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1
                )

            let json = [
                "userId": "userabc",
                "id":"observationabc"
            ]
            

            try await PersistenceContext.current!.persistence.write { context in
                Observation
                    .create(
                        feature: json,
                        context: context
                    )
            }
            
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1,
                    predicate: NSPredicate(format: "userId = %@", "userabc")
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    1
                )
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            )
        )
        func `verify that user fetch is called when an a user with no last updated is in the observation that is updated`() async throws {
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(Observation.self)) ?? [] {
                    context.delete(user)
                }
            }
            
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(User.self)) ?? [] {
                    context.delete(user)
                }
                let newUser = User(context: context)
                newUser.remoteId = "userabc"
                try context.obtainPermanentIDs(for: [newUser])
            }
            
            
            try await PersistenceContext.current!.persistence.write { context in
                let observation = Observation(context: context)
                observation.remoteId = "observationabc"
                observation.dirty = false
                let user = try context.fetchFirst(User.self)
                observation.user = user
                try context.obtainPermanentIDs(for: [observation])
            }
            
            let json = [
                "userId": "userabc",
                "id":"observationabc"
            ]
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1
                )
            

            try await PersistenceContext.current!.persistence.write { context in
                Observation
                    .create(
                        feature: json,
                        context: context
                    )
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Observation.self,
                    1,
                    predicate: NSPredicate(format: "userId = %@", "userabc")
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    1,
                    predicate: NSPredicate(format: "username = %@", "Myself")
                )
        }
        
    }
}
