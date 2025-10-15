//
//  Test+Helpers_NoUI.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import UIKit
@testable import Authentication
@testable import MAGE

// Wait loop for URL-hit assertions (uses MockMageServerDelegate.urls)
func waitForURL(_ url: URL, in delegate: MockMageServerDelegate, timeout: TimeInterval = 2.0, file: StaticString = #filePath, line: UInt = #line) {
    let exp = XCTestExpectation(description: "wait for \(url)")
    
    Task {
        let start = Date()
        
        while !delegate.urls.contains(url) {
            if Date().timeIntervalSince(start) > timeout {
                break
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        exp.fulfill()
    }
    
    XCTWaiter().wait(for: [exp], timeout: timeout + 0.1)
    XCTAssertTrue(delegate.urls.contains(url), "Expected \(url) to be called", file: file, line: line)
}

// Fetch currently presented alert, if there is one
@MainActor
func currentAlert(on nav: UINavigationController) -> UIAlertController? {
    if let a = nav.presentedViewController as? UIAlertController { return a }
    if let a = nav.topViewController as? UIAlertController { return a }
    return nil
}

// Small "seam" to read the "contact info" text in Login VC
@MainActor
func findLoginFailedText(in nav: UINavigationController) -> String? {
    guard let vc = nav.topViewController as? LoginHostViewController else { return nil }
    
    // If you can expose a `debug_contactMessage()` method on LoginHostViewController in DEBUG, call it here.
     return vc.debug_contactMessage
    
    // Or: walk the view hierarchy
//    return (vc.view.subviews.compactMap { $0 as? UITextView }.first?.attributedText.string)
}

// Toggle to simulate consent buttons
@MainActor
func agree(_ coordinator: AuthFlowCoordinator) {
    (coordinator as? DisclaimerDelegate)?.disclaimerAgree()
}

@MainActor
func disagree(_ coordinator: AuthFlowCoordinator) {
    (coordinator as? DisclaimerDelegate)?.disclaimerDisagree()
}

extension URLSession {
    func allTasksAsync() async -> [URLSessionTask] {
        await withCheckedContinuation { cont in
            self.getAllTasks { cont.resume(returning: $0) }
        }
    }

    /// Cancels all tasks and gives the runloop a moment to drain callbacks.
    func cancelAllTasksAndWaitASmidge() async {
        let tasks = await allTasksAsync()
        tasks.forEach { $0.cancel() }
        // Let AFNetworking/URLSession deliver cancellation callbacks
        try? await Task.sleep(nanoseconds: 150_000_000) // 150 ms
    }
}
