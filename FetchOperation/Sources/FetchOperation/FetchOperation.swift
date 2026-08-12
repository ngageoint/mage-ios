// The Swift Programming Language
// https://docs.swift.org/swift-book
import os

enum FetchOperationPackage {
    static let logger = Logger(subsystem: "FetchOperation", category: "FetchOperation")
    static func logger(_ category: String) -> Logger {
        return Logger(subsystem: "FetchOperation", category: category)
    }
}
