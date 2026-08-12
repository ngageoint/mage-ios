//
//  PipelineOperationMetadata.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/17/26.
//


public struct PipelineOperationMetadata: Sendable, Hashable, Equatable {
    
    public let operation: PipelineOperationKind
    public let phase: PipelineOperationPhase
    
    public init(
        operation: PipelineOperationKind,
        phase: PipelineOperationPhase
    ) {
        self.operation = operation
        self.phase = phase
    }
}
