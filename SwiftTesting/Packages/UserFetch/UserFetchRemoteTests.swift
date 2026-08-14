// 
//     
//  UserFetchRemoteTests.swift
//  MAGE
//
// 


import Testing
import Foundation
import Alamofire
import FetchOperation
import ServerDTO
import APIRouter
import TestUtilities
@testable import UserFetch
@testable import Pipeline

@testable import MAGE

struct UserFetchRemoteTests {
    let sut: UserFetchRemote
    
    init() {
        sut = UserFetchRemote(
            url: URL(string: "https://magetest")!,
            session: TokenAPISessionImpl(
                baseURL: URL(string: "https://magetest")!,
                loginType: "local",
                additionalHeaders: [HTTPStubTrait.HeaderKey:Test.current?.id.description ?? ""]
            ),
            eventID: EventID(1)
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
    func fetchReturnsUsersFromServer() async throws {
        var progressEvents: [OperationProgress] = []

        let users = try await sut.fetch { progress in
            progressEvents.append(progress)
        }

        #expect(users.count == 3)

        let first = try #require(users.first)

        #expect(first.username == "username")
        #expect(first.displayName == "username")
        #expect(first.email == "username@gmail.com")
        #expect(first.active == true)
        #expect(first.enabled == true)
        #expect(first.recentEventIds == [1, 14, 13, 2, 3])

        let third = try #require(users.last)

        #expect(third.username == "username2")
        #expect(third.active == false)
        #expect(third.phones?.count == 1)
        #expect(third.phones?.first?.number == "303-000-0000")
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
    func fetchReportsDownloadProgress() async throws {
        var receivedProgress = false

        _ = try await sut.fetch { progress in
            receivedProgress = true
        }

        #expect(receivedProgress)
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
    func fetchThrowsForServerError() async throws {
        await #expect(throws: Error.self) {
            _ = try await sut.fetch { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/users",
            responseString: "{ invalid json"
        )
    )
    func fetchThrowsForMalformedJSON() async {
        await #expect(throws: Error.self) {
            _ = try await sut.fetch { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/users",
            responseError: URLError(.notConnectedToInternet) as NSError
        )
    )
    func fetchThrowsUnderlyingTransportError() async {
        await #expect(throws: URLError.self) {
            _ = try await sut.fetch { _ in }
        }
    }
}
