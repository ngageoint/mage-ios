//
//  FetchRepositoryProtocol.swift
//  FetchOperation
//
//

import Pipeline

public protocol FetchRepositoryProtocol<Output>: Sendable {
    associatedtype Output: Sendable
    
    /// Starts a fetch operation.
    ///
    /// The returned operation begins executing immediately and can be
    /// observed independently of its execution lifecycle.
    func startFetch() -> any PipelineOperation<Output>
}
