//
//  UserRepositoryFactoryTests.swift
//

import Foundation
import CoreData
import Testing
import Alamofire
import ServerDTO
import APIRouter
import TestUtilities

@testable import UserFetch
@testable import FetchOperation
@testable import Persistence
@testable import MAGE
@testable import Pipeline

extension CoreDataTests {
    final class UserRepositoryFactoryTests {
        
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        let local: UserFetchLocalImpl
        let session: TokenAPISession
        
        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            local = UserFetchLocalImpl(persistence: persistence)
            session = TokenAPISessionImpl(
                baseURL: URL(string: "https://magetest")!,
                loginType: "local",
                additionalHeaders: [HTTPStubTrait.HeaderKey:Test.current?.id.description ?? ""]
            )
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
        func fetchRepository_fetchesAndSavesUsers() async throws {
            
            let repository = UserFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )
            
            var events: [PipelineOperationEvent] = []
            
            let operation = repository.startFetch(
                UserFetchRequest(eventID: EventID(1))
            )
            
            for try await event in operation.events() {
                events.append(event)
            }
            
            #expect(
                events.contains {
                    if case let .stateChanged(state) = $0 {
                        return state.metadata?.operation == UserFetchRepositoryFactory.UserFetchOperationKind
                        && state.metadata?.phase == .downloading
                    }
                    return false
                }
            )
            
            #expect(
                events.contains {
                    if case let .stateChanged(state) = $0 {
                        return state.metadata?.operation == UserFetchRepositoryFactory.UserFetchOperationKind
                        && state.metadata?.phase == .saving
                    }
                    return false
                }
            )
            
            let users = try await persistence.read { context in
                try context.fetchObjects(User.self)
            }
            
            #expect(users?.count == 3)
            print("Users count is \(users?.count ?? 0)")
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/users",
                statusCode: 500
            )
        )
        func fetchRepository_propagatesRemoteFailure() async {
            let repository = UserFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )
            
            await #expect(throws: Error.self) {
                let operation = repository.startFetch(
                    UserFetchRequest(eventID: EventID(1))
                )
                for try await _ in operation.events() { }
            }
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
        func fetchRepository_emitsDownloadingThenSaving() async throws {
            
            let repository = UserFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )
            
            var completedPhases: [PipelineOperationPhase] = []
            
            let operation = repository.startFetch(
                UserFetchRequest(eventID: EventID(1))
            )
            for try await event in operation.events() {
                if case let .stateChanged(state) = event {
                    print("State.status: \(state.status)")
                    if case .completed = state.status {
                        if let phase = state.metadata?.phase {
                            completedPhases.append(phase)
                        }
                    }
                    
                }
            }
            
            #expect(completedPhases == [
                .downloading,
                .saving
            ])
        }
    }
}
