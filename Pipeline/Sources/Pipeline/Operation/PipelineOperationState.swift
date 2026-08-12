//
//  PipelineOperationState.swift
//


import Foundation
import Synchronization

enum PipelineOperationError: Error {
    case cancelled
}

final class PipelineOperationState<Output: Sendable>:
    PipelineOperation<Output>,
    @unchecked Sendable
{
    private let reporter: PipelineOperationReporterStorage
    private let task: Task<Output, Error>
    
    init(
        kind: PipelineOperationKind,
        build: @escaping @Sendable (
            PipelineExecution<PipelineOperationReporterStorage>
        ) async throws -> Output
    ) {
        let reporter = PipelineOperationReporterStorage(
            kind: kind
        )
        
        self.reporter = reporter
        
        self.task = Task {
            do {
                let pipeline = PipelineExecution(reporter: reporter)
                let output = try await build(pipeline)
                
                reporter.finish()
                
                return output
            } catch {
                if Task.isCancelled {
                    reporter.cancelled()
                    throw PipelineOperationError.cancelled
                }
                
                reporter.fail(error)
                throw error
            }
        }
    }
    
    func value() async throws -> Output {
        try await task.value
    }
    
    func cancel() {
        task.cancel()
    }
    
    func events() -> AsyncThrowingStream<
        PipelineOperationEvent,
        Error
    > {
        reporter.events()
    }
    
    func snapshot() -> PipelineOperationSnapshot {
        reporter.snapshot()
    }
}
