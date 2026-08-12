//
//  AnyPipeline.swift
//

public struct AnyPipeline<Output: Sendable>: Sendable {
    
    private let _execute: @Sendable () ->
    any PipelineOperation<Output>
    
    public init<Context: Sendable>(
        _ pipeline: Pipeline<Context, Output>
    ) {
        self._execute = pipeline.execute
    }
    
    public func execute()
    -> any PipelineOperation<Output> {
        _execute()
    }
}
