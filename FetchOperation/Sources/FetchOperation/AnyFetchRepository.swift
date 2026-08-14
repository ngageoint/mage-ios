//
//  AnyFetchRepository.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/17/26.
//

import Foundation
import Pipeline

/// A type-erased fetch repository.
///
/// `AnyFetchRepository` wraps any type conforming to
/// `FetchRepositoryProtocol` and exposes it through a uniform interface.
///
/// A fetch begins immediately when `fetch()` is called. The returned
/// `FetchOperation` represents the in-flight work and may be observed by
/// zero or more consumers. Observation is optional and does not control
/// the lifetime of the fetch operation.
public struct AnyFetchRepository<Input: Sendable, Output: Sendable>:
    FetchRepositoryProtocol<Input, Output>,
    Sendable {
    
    private let fetchClosure: @Sendable (Input) ->
    any PipelineOperation<Output>
    
    
    /// Creates a type-erased fetch repository.
    ///
    /// - Parameter repository: The concrete fetch repository to wrap.
    public init<R: FetchRepositoryProtocol>(
        _ repository: R
    ) where R.Input == Input, R.Output == Output {
        self.fetchClosure = repository.startFetch
    }
    
    
    /// Starts a fetch operation.
    ///
    /// The returned operation begins executing immediately. Consumers may
    /// call `observe()` to receive progress and lifecycle events, but they
    /// are not required to observe the operation for it to complete.
    ///
    /// Multiple observers may subscribe to the returned operation. Dropping
    /// an observation stream does not cancel the fetch; cancellation must be
    /// requested explicitly through `FetchOperation.cancel()`.
    ///
    /// - Returns: A handle representing the running fetch operation.
    public func startFetch(
        _ input: Input
    ) -> any PipelineOperation<Output> {
        fetchClosure(input)
    }
}
