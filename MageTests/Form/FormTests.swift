//
//  FormTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import MAGE

class FormTests: AsyncMageCoreDataTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        TestHelpers.resetUserDefaults();
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.serverMajorVersion = 6;
        UserDefaults.standard.serverMinorVersion = 0;
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        TestHelpers.resetUserDefaults();
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    func testShouldPullTheFormsForAnEvent() {
        var stubCalled = false;
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/form/icons.zip")
        ) { (request) -> HTTPStubsResponse in
            stubCalled = true;
            let stubPath = OHPathForFile("plantsAnimalsBuildingsIcons.zip", FormTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
        }
        
        let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
        do {
            try FileManager.default.removeItem(atPath: folderToUnzipTo)
        } catch {
            NSLog("Error removing file at path: %@", error.localizedDescription);
        }
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());

        
        var formPullSuccessCalled = false;
        let task = Form.operationToPullFormIcons(eventId: 1) {
            formPullSuccessCalled = true;
        } failure: { error in
            
        }
        
        MageSessionManager.shared().addTask(task);
        
        expect(stubCalled).toEventually(beTrue());
        expect(formPullSuccessCalled).toEventually(beTrue());
        
        expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beTrue());
    }
    
    func testShouldFailWhenTheIconsZipIsNotAZip() {
        var stubCalled = false;
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/form/icons.zip")
        ) { (request) -> HTTPStubsResponse in
            stubCalled = true;
            let stubPath = OHPathForFile("icon27.png", FormTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
        }
        
        let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
        do {
            try FileManager.default.removeItem(atPath: folderToUnzipTo)
        } catch {
            NSLog("Error removing file at path: %@", error.localizedDescription);
        }
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
        
        
        var formPullFailureCalled = false;
        let task = Form.operationToPullFormIcons(eventId: 1) {
        } failure: { error in
            formPullFailureCalled = true;
        }
        
        MageSessionManager.shared().addTask(task);
        
        expect(stubCalled).toEventually(beTrue());
        expect(formPullFailureCalled).toEventually(beTrue());
        
        expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
    }
    
    func testShouldFailWhenTheServerReturnsAnError() {
        var stubCalled = false;
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/form/icons.zip")
        ) { (request) -> HTTPStubsResponse in
            stubCalled = true;
            return HTTPStubsResponse(error: NSError(domain: "bad", code: 503, userInfo: nil))
        }
        
        let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
        do {
            try FileManager.default.removeItem(atPath: folderToUnzipTo)
        } catch {
            NSLog("Error removing file at path: %@", error.localizedDescription);
        }
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
        
        
        var formPullFailureCalled = false;
        let task = Form.operationToPullFormIcons(eventId: 1) {
        } failure: { error in
            formPullFailureCalled = true;
        }
        
        MageSessionManager.shared().addTask(task);
        
        expect(stubCalled).toEventually(beTrue());
        expect(formPullFailureCalled).toEventually(beTrue());
        
        expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
        expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
    }
}
