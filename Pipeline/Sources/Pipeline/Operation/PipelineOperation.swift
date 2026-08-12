//
//  PipelineOperation.swift
//
//


import Foundation

/// Represents an executing pipeline operation.
///
/// An operation begins executing when it is created. Calling `events()`
/// observes the operation; it does not start or control execution.
///
/// Call `value()` to await the operation's result.
///
/// Call `cancel()` to request cancellation.
///
/// The event stream reports pipeline phase state. The stream terminates
/// when the operation finishes successfully, fails, or is cancelled.
public protocol PipelineOperation<Output>: Sendable {
    associatedtype Output: Sendable
    /// Observes progress and lifecycle events.
    ///
    /// The returned stream does not start or stop the operation.
    /// Dropping the stream does not cancel the operation.
    func events()
    -> AsyncThrowingStream<
        PipelineOperationEvent,
        Error
    >
    
    /// Requests cancellation of the operation.
    ///
    /// Cancellation is cooperative. If the operation is already complete,
    /// this has no effect.
    ///
    /// A cancelled operation causes `value()` to throw
    /// `PipelineOperationError.cancelled` and terminates its event stream
    /// after publishing the cancelled state.
    func cancel()
    
    /// Returns a point-in-time snapshot of the operation's observable state.
    ///
    /// The snapshot is safe to read concurrently with operation execution.
    func snapshot() -> PipelineOperationSnapshot
    
    func value() async throws -> Output
}
