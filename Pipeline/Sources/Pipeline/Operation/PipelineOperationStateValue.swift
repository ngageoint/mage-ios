//
//  PipelineOperationState.swift
//


public struct PipelineOperationStateValue: Sendable, Equatable {
    public let metadata: PipelineOperationMetadata?
    public let progress: PipelineOperationProgress?
    public let status: Status

    public enum Status: Sendable {
        case running
        case completed
        case failed
        case cancelled
    }

    public init(
        metadata: PipelineOperationMetadata?,
        progress: PipelineOperationProgress?,
        status: Status
    ) {
        self.metadata = metadata
        self.progress = progress
        self.status = status
    }
}
