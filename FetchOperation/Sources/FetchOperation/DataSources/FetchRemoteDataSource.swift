//
//  FetchRemoteDataSource.swift
//  FetchOperation
//
//


import Foundation
import Pipeline

// MARK: - Remote Data Source

public protocol FetchRemoteDataSource: Sendable {

    associatedtype DTO: Decodable & Sendable
    
    func fetch(
        urlRequest: URLRequest?,
        progress: @escaping OperationProgressHandler
    ) async throws -> [DTO]
}

extension FetchRemoteDataSource {
    public func fetch(
        progress: @escaping OperationProgressHandler
    ) async throws -> [DTO] {
        try await fetch(
            urlRequest: nil,
            progress: progress
        )
    }
}
