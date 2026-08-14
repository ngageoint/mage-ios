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
    
    private let pipeline: AnyPipeline<Output>
    
    public init(
        pipeline: AnyPipeline<Output>
    ) {
        self.pipeline = pipeline
    }
    
    
    public func startFetch(_ input: Input)
    -> any PipelineOperation<Output> {
        
        pipeline.execute()
    }
}
