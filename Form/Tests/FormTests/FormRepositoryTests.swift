//
//  FormRepositoryTests.swift
//  Form
//
//  Created by Daniel Barela on 1/10/26.
//


import Testing
import Combine
import APIRouter
import Persistence
import Foundation
import FetchOperation
import Pipeline
import ServerDTO

@testable import TestUtilities
@testable import Form

@MainActor
struct FormRepositoryTests {
    
    @Test(
        .timeLimit(.minutes(1)),
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/10/form/icons.zip",
            responseZip: "plantsAnimalsBuildingsIcons.zip"
        )
    )
    func `fetch icons`() async throws {
        var repository: AnyFetchRepository<FormIconFetchRequest, [URL]>!
        repository = FormRepositoryFactory
            .createFormIconFetchRepository(url: URL(string:"https://magetest")!, session: TestAPISession())
        
        let stream = repository.startFetch(FormIconFetchRequest(eventID: EventID(10)))
        let events = stream.events()
        var states: [PipelineOperationStateValue] = []
        for try await event in events {
            switch event {
                
            case .stateChanged(let state):
                if state.status == .completed {
                    states.append(state)
                }
            }
        }
        let finishValue = try await stream.value()
        
        #expect(finishValue.count == 1)
        
        #expect(states.count == 2)
        let first = try #require(states.first)
        #expect(first.metadata?.phase == .downloading)
        let last = try #require(states.last)
        #expect(last.metadata?.phase == .saving)
        print("testObserver.states \(states)")
    }
    
    @Test(
        .timeLimit(.minutes(1)),
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/form/icons.zip",
            statusCode: 401
        )
    )
    func `fetch icons token expired`() async throws {
        var repository: AnyFetchRepository<FormIconFetchRequest, [URL]>!
        repository = FormRepositoryFactory
            .createFormIconFetchRepository(url: URL(string:"https://magetest")!, session: TestAPISession())
        
        let stream = repository.startFetch(FormIconFetchRequest(eventID: EventID(1)))
        let events = stream.events()
        var states: [PipelineOperationStateValue] = []
        await #expect(throws: GeneralError.expiredToken.self) {
            
            for try await event in events {
                switch event {
                    
                case .stateChanged(let state):
                    if state.status == .failed {
                        states.append(state)
                    }
                }
            }
        }
        #expect(states.count == 1)
        let first = try #require(states.first)
        #expect(first.status == .failed)
    }
    
}
