//
//  OperationProgress.swift
//


public struct OperationProgress: Sendable {
    public let completed: Int64
    public let total: Int64

    public init(
        completed: Int64,
        total: Int64
    ) {
        self.completed = completed
        self.total = total
    }

    public var percentage: Double? {
        guard total > 0 else { return nil }
        return Double(completed) / Double(total)
    }

    public var isFinished: Bool {
        total > 0 && completed >= total
    }
}
