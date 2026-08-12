//
//  PipelineExecution.swift
//

import Foundation

public struct PipelineExecution<
    Reporter: PipelineOperationReporter
>: Sendable {
    private let reporter: Reporter
    
    init(
        reporter: Reporter
    ) {
        self.reporter = reporter
    }
    
    @discardableResult
    public func run<T: Sendable>(
        phase: PipelineOperationPhase,
        operation: @escaping @Sendable (
            @escaping @Sendable (OperationProgress) -> Void
        ) async throws -> T
    ) async throws -> T {
        let metadata = PipelineOperationMetadata(
            operation: reporter.kind,
            phase: phase
        )
        
        reporter.publish(
            .stateChanged(
                .init(
                    metadata: metadata,
                    progress: nil,
                    status: .running
                )
            )
        )
        
        let value = try await operation { operationProgress in
            let progress = PipelineOperationProgress(
                completed: operationProgress.completed,
                total: operationProgress.total,
                phase: phase
            )
            
            reporter.publish(
                .stateChanged(
                    .init(
                        metadata: metadata,
                        progress: progress,
                        status: .running
                    )
                )
            )
        }
        
        try Task.checkCancellation()
        
        reporter.publish(
            .stateChanged(
                .init(
                    metadata: metadata,
                    progress: nil,
                    status: .completed
                )
            )
        )
        
        return value
    }
}
