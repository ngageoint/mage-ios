//
//  FormRemoteDataSourceTests.swift
//  Form
//
//  Created by Daniel Barela on 1/9/26.
//

import Foundation
import Testing
import APIRouter
import TestUtilities
import ServerDTO

@testable import Form

struct FormRemoteDataSourceTests {

    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/125/form/icons.zip",
            responseZip: "plantsAnimalsBuildingsIcons.zip"
        )
    )
    func `fetch events`() async throws {
        let remoteDataSource = FormIconFetchRemote(url: URL(string:"https://magetest")!, session: TestAPISession(), eventID: EventID(125))
        actor ProgressTracker {
            var isFinished = false
            func updateIsFinished(isFinished: Bool) {
                self.isFinished = isFinished
            }
        }
        
        let tracker = ProgressTracker()
        let fileURLs = try await remoteDataSource.fetch() { progress in
            Task { await tracker.updateIsFinished(isFinished: progress.isFinished) }
        }
        let fileURL = try #require(fileURLs.first)
        await TestUtilities.waitForCondition({
            await tracker.isFinished
        }, timeout: 2.0, message: "Track was not finished")
        #expect(fileURL.isFileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path()))
        try FileManager.default.removeItem(at: fileURL)
        
        #expect(await tracker.isFinished)
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/11/form/icons.zip",
            statusCode: 401
        )
    )
    func `fetch events token expired`() async throws {
        let remoteDataSource = FormIconFetchRemote(url: URL(string:"https://magetest")!, session: TestAPISession(), eventID: EventID(11))
        
        await #expect(throws: GeneralError.expiredToken) {
            let fetched = try await remoteDataSource.fetch() { progress in
            }
        }
    }
}
