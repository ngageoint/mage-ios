//
//  PipelineOperationReporterStorage.swift
//

import Foundation
import Synchronization

final class PipelineOperationReporterStorage:
    PipelineOperationReporter,
    @unchecked Sendable
{
    private struct State {
        var continuations: [UUID: Continuation] = [:]
        var latestEvent: PipelineOperationEvent?
        var currentMetadata: PipelineOperationMetadata?
        var progress: PipelineOperationProgress?
        var finished = false
    }
    
    typealias Stream = AsyncThrowingStream<
        PipelineOperationEvent,
        Error
    >
    
    typealias Continuation = Stream.Continuation
    
    let kind: PipelineOperationKind
    
    private let lock = Mutex(State())
    
    init(
        kind: PipelineOperationKind
    ) {
        self.kind = kind
    }
    
    func events() -> Stream {
        Stream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            
            let id = UUID()
            
            let result = lock.withLock { state -> (
                PipelineOperationEvent?,
                Bool
            ) in
                let latestEvent = state.latestEvent
                
                if !state.finished {
                    state.continuations[id] = continuation
                }
                
                return (
                    latestEvent,
                    state.finished
                )
            }
            
            if let event = result.0 {
                continuation.yield(event)
            }
            
            if result.1 {
                continuation.finish()
                return
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(id)
            }
        }
    }
    
    func publish(
        _ event: PipelineOperationEvent
    ) {
        let (publishedEvent, continuations) = lock.withLock { state -> (
            PipelineOperationEvent,
            [Continuation]
        ) in
            guard case let .stateChanged(operationState) = event else {
                state.latestEvent = event
                return (
                    event,
                    Array(state.continuations.values)
                )
            }
            
            let progress: PipelineOperationProgress?
            
            switch operationState.status {
            case .running:
                progress = operationState.progress
                
            case .completed, .failed, .cancelled:
                progress = operationState.progress ?? state.progress
            }
            
            let publishedEvent = PipelineOperationEvent.stateChanged(
                PipelineOperationStateValue(
                    metadata: operationState.metadata,
                    progress: progress,
                    status: operationState.status
                )
            )
            
            state.currentMetadata = operationState.metadata
            state.progress = progress
            state.latestEvent = publishedEvent
            
            return (
                publishedEvent,
                Array(state.continuations.values)
            )
        }
        
        for continuation in continuations {
            continuation.yield(publishedEvent)
        }
    }
    
    func finish() {
        let continuations = lock.withLock { state -> [Continuation] in
            state.finished = true
            
            let result = Array(state.continuations.values)
            state.continuations.removeAll()
            
            return result
        }
        
        for continuation in continuations {
            continuation.finish()
        }
    }
    
    func fail(_ error: Error) {
        let event = lock.withLock { state -> PipelineOperationEvent in
            PipelineOperationEvent.stateChanged(
                PipelineOperationStateValue(
                    metadata: state.currentMetadata,
                    progress: state.progress,
                    status: .failed
                )
            )
        }
        
        finishStreams(
            with: event,
            throwing: error
        )
    }
    
    func cancelled() {
        let event = lock.withLock { state -> PipelineOperationEvent in
            PipelineOperationEvent.stateChanged(
                PipelineOperationStateValue(
                    metadata: state.currentMetadata,
                    progress: state.progress,
                    status: .cancelled
                )
            )
        }
        
        finishStreams(with: event)
    }
    
    func snapshot() -> PipelineOperationSnapshot {
        lock.withLock { state in
            PipelineOperationSnapshot(
                latestEvent: state.latestEvent,
                currentPhase: state.currentMetadata?.phase,
                progress: state.progress,
                isFinished: state.finished
            )
        }
    }
    
    private func removeContinuation(
        _ id: UUID
    ) {
        lock.withLock { state in
            state.continuations[id] = nil
        }
    }

    
    private func finishStreams(
        with event: PipelineOperationEvent,
        throwing error: Error? = nil
    ) {
        let continuations = lock.withLock { state -> [Continuation] in
            state.latestEvent = event
            state.finished = true
            
            let result = Array(state.continuations.values)
            state.continuations.removeAll()
            
            return result
        }
        
        for continuation in continuations {
            continuation.yield(event)
            
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}
