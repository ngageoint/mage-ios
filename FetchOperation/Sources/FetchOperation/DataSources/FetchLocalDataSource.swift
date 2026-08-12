//
//  FetchLocalDataSource.swift
//  FetchOperation
//
//


import Foundation
import Pipeline

// MARK: - Local Data Source

public protocol FetchLocalDataSource: Sendable {

    associatedtype DTO: Decodable & Sendable
    associatedtype SaveResult: Sendable

    @discardableResult
    func save(
        _ dto: [DTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult
}
