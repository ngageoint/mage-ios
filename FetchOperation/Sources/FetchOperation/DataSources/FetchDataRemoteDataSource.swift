//
//  FetchDataRemoteDataSource.swift
//  FetchOperation
//
//  Created by Daniel Barela on 8/12/26.
//

import Foundation
import Pipeline

public protocol FetchDataRemoteDataSource: Sendable {
        
    func fetch(
        urlRequest: URLRequest?,
        progress: @escaping OperationProgressHandler
    ) async throws -> Data
}

extension FetchDataRemoteDataSource {
    public func fetch(
        progress: @escaping OperationProgressHandler
    ) async throws -> Data {
        try await fetch(
            urlRequest: nil,
            progress: progress
        )
    }
}
