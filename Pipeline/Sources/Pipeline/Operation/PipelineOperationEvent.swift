//
//  PipelineOperationEvent.swift
//
//

/// Describes a state transition within a pipeline operation.
///
/// Each pipeline phase emits a `.running` event followed by a terminal
/// `.completed`, `.failed`, or `.cancelled` state as appropriate.
///
/// Operation-level completion is represented by termination of the event
/// stream; there is no additional operation-level `.completed` event.
public enum PipelineOperationEvent: Sendable, Equatable {
    
    case stateChanged(PipelineOperationStateValue)
}
