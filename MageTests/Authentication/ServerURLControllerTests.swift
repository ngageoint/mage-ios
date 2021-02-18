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
    func setServerURL(_ url: URL!) {
        setServerURLCalled = true;
        newURL = url;
    }
    
    func cancelSetServerURL() {
        cancelSetServerURLCalled = true;
    }
}

class ServerURLControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("ServerURLControllerTests") {
            
            var window: UIWindow?;
            var view: ServerURLController?;
            var delegate: MockServerURLDelegate?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window?.autoSetDimension(.width, toSize: 414);
                window?.autoSetDimension(.height, toSize: 896);
                                
                delegate = MockServerURLDelegate();
                navigationController = UINavigationController();
                window?.rootViewController = navigationController;
                window?.makeKeyAndVisible();
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                delegate = nil;
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
            }
            
            it("should load empty the ServerURLController") {
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Cancel");
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
            }
            
            it("should not allow setting an empty server URL") {
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).to(beFalse());
                
                expect(viewTester().usingLabel("Server URL Error")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL Error")?.view, toContainText: "Invalid URL");
            }
            
            it("should allow setting a server URL") {
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                tester().clearTextFromView(withAccessibilityLabel: "Server URL");
                tester().enterText("https://magetest", intoViewWithAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).toEventually(beTrue());
                expect(delegate?.newURL).toEventually(equal(URL(string: "https://magetest")));
            }
            
            it("should allow setting a server URL with the enter key") {
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                tester().clearTextFromView(withAccessibilityLabel: "Server URL");
                tester().enterText("https://magetest\n", intoViewWithAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "OK");
                expect(delegate?.setServerURLCalled).toEventually(beTrue());
                expect(delegate?.newURL).toEventually(equal(URL(string: "https://magetest")));
            }
            
            it("should load current URL into the ServerURLController") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
            }
            
            it("should load current URL into the ServerURLController with an error") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, andError: "Something wrong", andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().waitForView(withAccessibilityLabel: "Server URL Error");
                expect(viewTester().usingLabel("Server URL Error")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL Error")?.view, toContainText: "Something wrong");
            }
            
            it("should cancel the ServerURLController") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                view = ServerURLController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ServerURLController.self));
                tester().waitForView(withAccessibilityLabel: "Server URL");
                expect(viewTester().usingLabel("Server URL")?.view).toEventuallyNot(beNil());
                tester().expect(viewTester().usingLabel("Server URL")?.view, toContainText: "https://magetest");
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("OK")?.view).toEventuallyNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "Cancel");
                expect(delegate?.cancelSetServerURLCalled).toEventually(beTrue());
            }
        }
    }
}
