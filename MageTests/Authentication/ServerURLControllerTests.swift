//
//  ServerURLControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher

@testable import MAGE

@available(iOS 13.0, *)

class MockServerURLDelegate: ServerURLDelegate {
    var setServerURLCalled = false;
    var cancelSetServerURLCalled = false;
    var newURL: URL?;
    func setServerURL(url: URL) {
        setServerURLCalled = true;
        newURL = url;
    }
    
    func cancelSetServerURL() {
        cancelSetServerURLCalled = true;
    }
}

class ServerURLControllerTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("ServerURLControllerTests") {
            
            var window: UIWindow?;
            var view: ServerURLController?;
            var delegate: MockServerURLDelegate!;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                                
                delegate = MockServerURLDelegate();
                navigationController = UINavigationController();
                
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                delegate = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("should load empty the ServerURLController") {
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Cancel");
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
            }
            
            it("should not allow setting an empty server URL") {
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).to(beFalse());
                
                expect(viewTester().usingLabel("Server URL Error")?.view).toNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL Error")?.view, toContainText: "Invalid URL");
            }
            
            it("should allow setting a server URL") {
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                tester().clearTextFromView(withAccessibilityLabel: "Server URL");
                tester().enterText("https://magetest", intoViewWithAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).to(beTrue());
                expect(delegate?.newURL).toEventually(equal(URL(string: "https://magetest")));
            }
            
            it("should allow setting a server URL with the enter key") {
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                tester().clearTextFromView(withAccessibilityLabel: "Server URL");
                tester().enterText("https://magetest\n", intoViewWithAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).toEventually(beTrue());
                expect(delegate?.newURL).toEventually(equal(URL(string: "https://magetest")));
            }
            
            it("should load current URL into the ServerURLController") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");

                expect(viewTester().usingLabel("Cancel")?.view).toNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
            }
            
            it("should load current URL into the ServerURLController with an error") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, error: "Something wrong", scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Something wrong");
                expect(viewTester().usingLabel("Something wrong")?.view).toNot(beNil());

                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().waitForView(withAccessibilityLabel: "Server URL Error");
                expect(viewTester().usingLabel("Server URL Error")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL Error")?.view, toContainText: "Something wrong");
            }
            
            it("should cancel the ServerURLController") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");
                expect(viewTester().usingLabel("Cancel")?.view).toNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "Cancel");
                expect(delegate?.cancelSetServerURLCalled).to(beTrue());
            }
        }
    }
}
