//
//  PipelineOperationReporter.swift
//  FetchOperation
//
//  Created by Daniel Barela on 8/11/26.
//

public protocol PipelineOperationReporter: Sendable {
    var kind: PipelineOperationKind { get }
    
    func publish(_ event: PipelineOperationEvent)
}
