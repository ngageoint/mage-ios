//
//  FetchRepository.swift
//  FetchOperation
//
//


import Foundation
import Pipeline

public final class FetchRepository<Input: Sendable, Output: Sendable>:
    FetchRepositoryProtocol,
    Sendable {
    
    private let fetch: @Sendable (Input) -> any PipelineOperation<Output>
    
    public init(
        fetch: @escaping @Sendable (Input) -> any PipelineOperation<Output>
    ) {
        self.fetch = fetch
    }
    
    
    public func startFetch(
        _ input: Input
    ) -> any PipelineOperation<Output> {
        fetch(input)
    }
}
