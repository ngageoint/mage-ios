//
//  MainActorGate.swift
//  MAGETests
//
//  Created by Brent Michalski on 9/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Run work on the main actor synchronously from nonisolatged congtexts (Quick/KIF closures)
enum MainActorGate {
    @discardableResult
    static func runSync<T>(
        _ timeout: TimeInterval = 10,
        _ body: @escaping @MainActor () -> T
    ) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: T!
        
        Task { @MainActor in
            result = body()
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + timeout)
        return result
    }
    
    static func runSync(
        _ timeout: TimeInterval = 10,
        _ body: @escaping @MainActor () -> Void
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        
        Task { @MainActor in
            body()
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + timeout)
    }
}


//import Quick
//
//func beforeEachOnMain(_ body: @escaping @MainActor () -> Void) {
//    beforeEach { MainActorGate.runSync(body) }
//}
//
//func afterEachOnMain(_ body: @escaping @MainActor () -> Void) {
//    afterEach { MainActorGate.runSync(body) }
//}
//
//func itOnMain(_ description: String,
//              file: StaticString = #filePath,
//              line: UInt = #line,
//              _ body: @escaping @MainActor () -> Void) {
//    it(description, file: file, line: line) {
//        MainActorGate.runSync(body)
//    }
//}
