//
//  PipelineOperationPhase.swift
//


public struct PipelineOperationPhase: Sendable, Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension PipelineOperationPhase {
    var displayName: String {
        rawValue.camelCaseToSpaces()
    }
}
