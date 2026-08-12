//
//  PipelineOperationSnapshot.swift
//

/// A point-in-time representation of a pipeline operation's state.
public struct PipelineOperationSnapshot: Sendable {
    public let latestEvent: PipelineOperationEvent?
    public let currentPhase: PipelineOperationPhase?
    public let progress: PipelineOperationProgress?
    public let isFinished: Bool
}
