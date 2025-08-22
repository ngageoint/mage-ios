//
//  SettingsTableViewControllerContactUsTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import UIKit
import ObjectiveC.runtime

@testable import MAGE

// MARK: - Test harness captured state
private final class ContactUsHarness {
    static let shared = ContactUsHarness()
    var canOpen = true
    var openURLCallCount = 0
    var lastOpenedURL: URL?
    var lastOpenOptions: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]

    func reset(canOpen: Bool) {
        self.canOpen = canOpen
        openURLCallCount = 0
        lastOpenedURL = nil
        lastOpenOptions = [:]
    }
}

// MARK: - Swizzles
private var originalCanOpenURL: Method?
private var swizzledCanOpenURL: Method?
private var originalOpenURLOptions: Method?
private var swizzledOpenURLOptions: Method?

private func swizzleUIApplication() {
    let cls: AnyClass = UIApplication.self

    originalCanOpenURL = class_getInstanceMethod(cls, #selector(UIApplication.canOpenURL(_:)))
    swizzledCanOpenURL = class_getInstanceMethod(cls, #selector(UIApplication.test_canOpenURL(_:)))
    if let o = originalCanOpenURL, let s = swizzledCanOpenURL { method_exchangeImplementations(o, s) }

    originalOpenURLOptions = class_getInstanceMethod(cls, #selector(UIApplication.open(_:options:completionHandler:)))
    swizzledOpenURLOptions = class_getInstanceMethod(cls, #selector(UIApplication.test_openURL(_:options:completionHandler:)))
    if let o = originalOpenURLOptions, let s = swizzledOpenURLOptions { method_exchangeImplementations(o, s) }
}

private func unswizzleUIApplication() {
    if let o = originalCanOpenURL, let s = swizzledCanOpenURL { method_exchangeImplementations(s, o) }
    if let o = originalOpenURLOptions, let s = swizzledOpenURLOptions { method_exchangeImplementations(s, o) }
}

extension UIApplication {
    // Exact Obj-C selector names so swizzling matches.
    @objc(test_canOpenURL:)
    func test_canOpenURL(_ url: URL) -> Bool {
        return ContactUsHarness.shared.canOpen
    }

    @objc(test_openURL:options:completionHandler:)
    func test_openURL(_ url: URL,
                      options: [UIApplication.OpenExternalURLOptionsKey: Any],
                      completionHandler: ((Bool) -> Void)?) {
        let h = ContactUsHarness.shared
        h.openURLCallCount += 1
        h.lastOpenedURL = url
        h.lastOpenOptions = options
        completionHandler?(h.canOpen)
    }
}

// MARK: - Tests
final class SettingsTableViewControllerContactUsTests: XCTestCase {

    private func invokeContactUs(_ sut: SettingsTableViewController) {
        let sel = NSSelectorFromString("onContactUs")
        XCTAssertTrue(sut.responds(to: sel), "SettingsTableViewController should respond to onContactUs")
        _ = sut.perform(sel)
    }
    
    override func setUp() {
        super.setUp()
        swizzleUIApplication()
        clearDefaults()
        ContactUsHarness.shared.reset(canOpen: true)
    }

    override func tearDown() {
        clearDefaults()
        unswizzleUIApplication()
        super.tearDown()
    }

    private func clearDefaults() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "contactInfoEmail")
        // if your Swift property exists, clear via KVC too
        d.setValue(nil, forKey: "contactInfoEmail")
    }

    private func setContactEmail(_ email: String?) {
        let d = UserDefaults.standard
        // works whether you have a Swift @objc property or just a raw key
        d.setValue(email, forKey: "contactInfoEmail")
        if let email { d.set(email, forKey: "contactInfoEmail") } else { d.removeObject(forKey: "contactInfoEmail") }
    }

    private func makeSUT() -> SettingsTableViewController {
        // Uses UITableViewController init; nothing else in onContactUs depends on properties.
        return SettingsTableViewController(style: .grouped)
    }

    // 1) configured email + Mail available → opens configured mailto
    func test_onContactUs_usesConfiguredEmail_whenAvailable_andOpensMail() {
        setContactEmail("support@acme.example")
        ContactUsHarness.shared.reset(canOpen: true)

        let sut = makeSUT()
        invokeContactUs(sut)

        XCTAssertEqual(ContactUsHarness.shared.openURLCallCount, 1)
        XCTAssertEqual(ContactUsHarness.shared.lastOpenedURL?.scheme, "mailto")
        XCTAssertEqual(ContactUsHarness.shared.lastOpenedURL?.absoluteString, "mailto:support@acme.example")
    }

    // 2) no configured email + Mail available → opens fallback mailto
    func test_onContactUs_usesFallbackEmail_whenMissing_andOpensMail() {
        setContactEmail(nil)
        ContactUsHarness.shared.reset(canOpen: true)

        let sut = makeSUT()
        invokeContactUs(sut)

        XCTAssertEqual(ContactUsHarness.shared.openURLCallCount, 1)
        XCTAssertEqual(ContactUsHarness.shared.lastOpenedURL?.absoluteString, "mailto:magesuitesupport@nga.mil")
    }

    // 3) empty configured email + Mail available → uses fallback
    func test_onContactUs_emptyEmail_usesFallback_andOpensMail() {
        setContactEmail("") // empty string should trigger fallback
        ContactUsHarness.shared.reset(canOpen: true)

        let sut = makeSUT()
        invokeContactUs(sut)

        XCTAssertEqual(ContactUsHarness.shared.openURLCallCount, 1)
        XCTAssertEqual(ContactUsHarness.shared.lastOpenedURL?.absoluteString, "mailto:magesuitesupport@nga.mil")
    }

    // 4) configured email + Mail NOT available → does not open
    func test_onContactUs_configuredEmail_butCannotOpen_doesNotOpenMail() {
        setContactEmail("support@acme.example")
        ContactUsHarness.shared.reset(canOpen: false)

        let sut = makeSUT()
        invokeContactUs(sut)

        XCTAssertEqual(ContactUsHarness.shared.openURLCallCount, 0)
        XCTAssertNil(ContactUsHarness.shared.lastOpenedURL)
    }

    // 5) no configured email + Mail NOT available → does not open
    func test_onContactUs_missingEmail_andCannotOpen_doesNotOpenMail() {
        setContactEmail(nil)
        ContactUsHarness.shared.reset(canOpen: false)

        let sut = makeSUT()
        invokeContactUs(sut)

        XCTAssertEqual(ContactUsHarness.shared.openURLCallCount, 0)
        XCTAssertNil(ContactUsHarness.shared.lastOpenedURL)
    }
}
