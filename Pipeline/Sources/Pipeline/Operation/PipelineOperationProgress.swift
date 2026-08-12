//
//  PipelineOperationProgress.swift
//

/// Progress reported by the currently executing pipeline phase.
///
/// Progress belongs to a phase. When a new phase begins, progress from
/// the previous phase is cleared.
///
/// A terminal state retains the most recently reported progress for
/// that phase.
public struct PipelineOperationProgress: Sendable, Equatable {
    public let completed: Int64
    public let total: Int64
    public let phase: PipelineOperationPhase
    
    public init(completed: Int64, total: Int64, phase: PipelineOperationPhase) {
        self.completed = completed
        self.total = total
        self.phase = phase
    }
    
    public var percentage: Double? {
        guard total > 0 else { return nil }
        return Double(completed) / Double(total)
    }
    
    public var isFinished: Bool {
        total > 0 && completed >= total
    }
}
