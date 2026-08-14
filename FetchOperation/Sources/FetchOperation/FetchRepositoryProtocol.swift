//
//  FetchRepositoryProtocol.swift
//  FetchOperation
//
//

import Pipeline

public protocol FetchRepositoryProtocol<Input, Output>: Sendable {
    associatedtype Output: Sendable
    associatedtype Input: Sendable
    
    /// Starts a fetch operation.
    ///
    /// The returned operation begins executing immediately and can be
    /// observed independently of its execution lifecycle.
    func startFetch(
        _ input: Input
    ) -> any PipelineOperation<Output>
}

public extension FetchRepositoryProtocol where Input == Void {
    func startFetch() -> any PipelineOperation<Output> {
        startFetch(())
    }
}
