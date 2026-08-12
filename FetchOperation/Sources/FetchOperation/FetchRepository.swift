//
//  FetchRepository.swift
//  FetchOperation
//
//


import Foundation
import Pipeline

public final class FetchRepository<Output: Sendable>:
    FetchRepositoryProtocol,
    Sendable {
    
    private let pipeline: AnyPipeline<Output>
    
    public init(
        pipeline: AnyPipeline<Output>
    ) {
        self.pipeline = pipeline
    }
    
    
    public func startFetch()
    -> any PipelineOperation<Output> {
        
        pipeline.execute()
    }
}
