//
//  PipelineOperationKind.swift
//
//


import Foundation

public struct PipelineOperationKind: Sendable, Equatable, Hashable {
    let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension PipelineOperationKind {
    
    public var displayName: String {
        rawValue.camelCaseToSpaces()
    }
}

extension String {
    func camelCaseToSpaces() -> String {
        return self.replacingOccurrences(of: "([A-Z])",
                                         with: " $1",
                                         options: .regularExpression,
                                         range: range(of: self))
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .capitalized
    }
}
