//
//  FetchRepositoryProtocol.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/17/26.
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
