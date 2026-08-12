//
//  PipelineStep.swift
//


public struct PipelineStep<Context: Sendable>: Sendable {
    
    let phase: PipelineOperationPhase
    
    let perform: @Sendable (
        Context,
        @escaping @Sendable (OperationProgress) -> Void
    ) async throws -> Context
    
    public init(
        phase: PipelineOperationPhase,
        perform: @escaping @Sendable (
            Context,
            @escaping @Sendable (OperationProgress) -> Void
        ) async throws -> Context
    ) {
        self.phase = phase
        self.perform = perform
    }
}
