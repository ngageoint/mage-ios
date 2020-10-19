//
//  LocalLoginViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import Kingfisher
import OHHTTPStubs

@testable import MAGE

@available(iOS 13.0, *)

class MockLoginDelegate: LoginDelegate {
    var loginParameters: [AnyHashable : Any]?;
    var loginCalled = false;
    var authenticationType: AuthenticationType?;
    var changeServerURLCalled = false;
    var createAccountCalled = false;
    
    func login(withParameters parameters: [AnyHashable : Any]!, with authenticationType: AuthenticationType, complete: ((AuthenticationStatus, String?) -> Void)!) {
        loginCalled = true;
        loginParameters = parameters;
        self.authenticationType = authenticationType;
    }
    
    func changeServerURL() {
        changeServerURLCalled = true;
    }
    
    func createAccount() {
        createAccountCalled = true;
    }
}

class LocalLoginViewTests: KIFSpec {
    
    override func spec() {
        
        describe("LocalLoginViewTests") {
            
            var window: UIWindow?;
            var view: UIView!;
            var localLoginView: LocalLoginView!;
            var controller: ContainingUIViewController?;
            var delegate: MockLoginDelegate!;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window?.autoSetDimension(.width, toSize: 414);
                window?.makeKeyAndVisible();
                
                UserDefaults.MageServerDefaults.set("https://magetest", forKey: .baseServerUrl);
                                
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                
                controller = ContainingUIViewController();
                window?.rootViewController = controller;
                controller?.view.addSubview(view);
                
                delegate = MockLoginDelegate();
            }
            
            afterEach {
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                view = nil;
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
                HTTPStubs.removeAllStubs();
            }
            
            it("should load the Local Login View as a nib") {
                localLoginView = UINib(nibName: "local-authView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as! LocalLoginView;
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Local Login View");
                tester().waitForView(withAccessibilityLabel: "Username");
                tester().waitForView(withAccessibilityLabel: "Password");
                tester().waitForView(withAccessibilityLabel: "Sign In")
            }
            
            it("should load the Local Login View") {
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Local Login View");
                tester().waitForView(withAccessibilityLabel: "Username");
                tester().waitForView(withAccessibilityLabel: "Password");
                tester().waitForView(withAccessibilityLabel: "Sign In")
            }
            
            it("should load the proceed to each field in order") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let uuidString: String = DeviceUUID.retrieveDeviceUUID()!.uuidString;
                let appVersion: String = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)-\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)";
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
                localLoginView.delegate = delegate;
                localLoginView.strategy = strategy as [AnyHashable : Any];
                
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Username");
                tester().waitForView(withAccessibilityLabel: "Password");
                tester().waitForView(withAccessibilityLabel: "Sign In");
                
                tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
                tester().waitForFirstResponder(withAccessibilityLabel: "Password");
                tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password");
                
                expect(delegate.loginCalled).toEventually(beTrue());
                
                let expectedLoginParameters: [AnyHashable: Any?] = [
                    "username": "username",
                    "password": "password",
                    "strategy": [
                        "passwordMinLength": 14
                    ],
                    "uid":uuidString,
                    "appVersion": appVersion
                ];
                expect(delegate.loginParameters!["username"] as? String).to(equal(expectedLoginParameters["username"] as? String));
                expect(delegate.loginParameters!["password"] as? String).to(equal(expectedLoginParameters["password"] as? String));
                expect(delegate.loginParameters!["uid"] as? String).to(equal(expectedLoginParameters["uid"] as? String));
                expect(delegate.loginParameters!["appVersion"] as? String).to(equal(expectedLoginParameters["appVersion"] as? String));
            }
        }
    }
}
