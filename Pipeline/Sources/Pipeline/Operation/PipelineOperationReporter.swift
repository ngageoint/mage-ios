//
//  PipelineOperationReporter.swift
//

public protocol PipelineOperationReporter: Sendable {
    var kind: PipelineOperationKind { get }
    
    func publish(_ event: PipelineOperationEvent)
}
