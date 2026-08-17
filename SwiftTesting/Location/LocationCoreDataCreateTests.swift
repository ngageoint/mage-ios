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
    struct LocationCoreDataCreateTests {
        
        @Test(
            // go fetch the new user we found
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            ),
            // go fetch the locations
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                responseFile: "locationsabc.json"
            ),
            // since there is a new user, we go fetch all the event users
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/users",
                responseFile: "eventUsers.json"
            )
        )
        func `verify that user fetch is called when a location with a new user is inserted`() async throws {
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(User.self)) ?? [] {
                    context.delete(user)
                }
                for location in (try? context.fetchObjects(Location.self)) ?? [] {
                    context.delete(location)
                }
            }
            UserDefaults.standard.baseServerUrl = "https://magetest"
            if let testId = Test.current?.id.description {
                MageSessionManager
                    .shared().requestSerializer
                    .setValue(
                        testId,
                        forHTTPHeaderField: HTTPStubTrait.HeaderKey
                    )
            }
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            
            let task = Location.operationToPullLocations { task, any in
                
            } failure: { task, any in
                
            }
            task?.resume()
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Location.self,
                    1
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    3 // this is 3 because we went to fetch all the event users
                )
        }
        
        @Test(
            // go fetch the new user we found
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/users/userabc",
                responseFile: "myself.json"
            ),
            // go fetch the locations
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                responseFile: "locationsabc.json",
            )
        )
        func `verify that user fetch is called when an a user with no last updated is in the location`() async throws {
            _ = try await PersistenceContext.current!.persistence.write { context in
                for user in (try? context.fetchObjects(User.self)) ?? [] {
                    context.delete(user)
                }
                for location in (try? context.fetchObjects(Location.self)) ?? [] {
                    context.delete(location)
                }
            }
            UserDefaults.standard.baseServerUrl = "https://magetest"
            if let testId = Test.current?.id.description {
                MageSessionManager
                    .shared().requestSerializer
                    .setValue(
                        testId,
                        forHTTPHeaderField: HTTPStubTrait.HeaderKey
                    )
            }
            await DependencyContainer.shared.configure(
                url: URL(string:"https://magetest")!,
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
            
            _ = try await PersistenceContext.current!.persistence.write { context in
                let newUser = User(context: context)
                newUser.remoteId = "userabc"
                try context.obtainPermanentIDs(for: [newUser])
            }
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Location.self,
                    0
                )
            let task = Location.operationToPullLocations { task, any in
                
            } failure: { task, any in
                
            }
            task?.resume()
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    Location.self,
                    1
                )
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    PersistenceContext.current!.persistence,
                    User.self,
                    1, // this is 1 because we only fetched the information for the user we needed to add
                    predicate: NSPredicate(format: "username = %@", "Myself")
                )
        }
    }
}
