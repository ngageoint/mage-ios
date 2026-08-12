# Pipeline

A lightweight, concurrency-safe Swift pipeline framework for composing asynchronous operations into ordered, observable steps.

`Pipeline` separates **pipeline orchestration** from the work performed by individual steps. A pipeline receives an initial `Context`, executes a sequence of `PipelineStep`s, reports phase and progress information, and produces a final `Output`.

The package is designed for Swift 6 concurrency and uses `async/await`, `Sendable`, and `AsyncThrowingStream` rather than Combine.

## Requirements

- Swift 6.3+
- iOS 18+
- Swift language mode 6

## Core Concepts

A pipeline consists of four primary pieces:

```text
Context
   │
   ▼
┌─────────────┐
│ PipelineStep│
│   Phase 1   │
└──────┬──────┘
       │ Context
       ▼
┌─────────────┐
│ PipelineStep│
│   Phase 2   │
└──────┬──────┘
       │ Context
       ▼
┌─────────────┐
│ PipelineStep│
│   Phase 3   │
└──────┬──────┘
       │ Context
       ▼
     Output
```

### `Pipeline`

`Pipeline<Context, Output>` defines the pipeline itself.

A pipeline contains:

- An operation identifier
- An initial context
- An ordered collection of steps
- A transformation from the final context to the output

Creating a pipeline does not execute it. Calling `execute()` creates a `PipelineOperation` and immediately starts execution.

### `PipelineStep`

A `PipelineStep` represents one phase of a pipeline.

Each step:

1. Receives the current context.
2. Performs asynchronous work.
3. Optionally reports progress.
4. Returns the context that will be passed to the next step.

Steps are strongly typed to the pipeline's context.

```swift
PipelineStep<MyContext>(
    phase: PipelineOperationPhase(rawValue: "downloading")
) { context, progress in

    // Perform asynchronous work...

    progress(
        OperationProgress(
            completed: 50,
            total: 100
        )
    )

    return context
}
```

### `PipelineExecution`

`PipelineExecution` is the execution environment provided to a running pipeline.

It is responsible for executing individual phases and translating their progress into pipeline-level events.

Most pipeline implementations do not need to interact with `PipelineExecution` directly. It is primarily used internally by `Pipeline`.

### `PipelineOperation`

Calling `execute()` returns an `any PipelineOperation<Output>`.

The operation:

- Starts immediately.
- Can be awaited with `value()`.
- Can be observed with `events()`.
- Can be cancelled with `cancel()`.
- Provides a point-in-time `snapshot()`.

```swift
let operation = pipeline.execute()

let result = try await operation.value()
```

Observation is independent from execution. Creating or dropping an event stream does not start, stop, or cancel the operation.

---

## Building a Pipeline

A simple pipeline can be created with a strongly typed context:

```swift
struct Context: Sendable {
    var value: Int
}

let pipeline = Pipeline<Context, Int>(
    operation: PipelineOperationKind(rawValue: "calculate"),
    context: Context(value: 1)
) {
    PipelineStep<Context>(
        phase: PipelineOperationPhase(rawValue: "incrementing")
    ) { context, _ in
        var context = context
        context.value += 1
        return context
    }

    PipelineStep<Context>(
        phase: PipelineOperationPhase(rawValue: "doubling")
    ) { context, _ in
        var context = context
        context.value *= 2
        return context
    }
} output: {
    $0.value
}
```

Executing the pipeline:

```swift
let operation = pipeline.execute()

let result = try await operation.value()

// result == 4
```

Steps execute sequentially, with the output of one step becoming the input to the next.

---

## Pipeline Builder

`PipelineBuilder` is a Swift result builder that allows pipeline steps to be declared naturally.

Conditional and repeated steps are supported:

```swift
let includeOptionalStep = true

let pipeline = Pipeline<Context, Int>(
    operation: PipelineOperationKind(rawValue: "calculate"),
    context: Context(value: 1)
) {
    PipelineStep(
        phase: PipelineOperationPhase(rawValue: "first")
    ) { context, _ in
        context
    }

    if includeOptionalStep {
        PipelineStep(
            phase: PipelineOperationPhase(rawValue: "optional")
        ) { context, _ in
            context
        }
    }
} output: {
    $0.value
}
```

The builder produces an ordered array of `PipelineStep`s before execution begins.

---

## Progress Reporting

Progress is reported by a pipeline step through `OperationProgress`:

```swift
progress(
    OperationProgress(
        completed: 25,
        total: 100
    )
)
```

`OperationProgress` provides:

- `completed`
- `total`
- `percentage`
- `isFinished`

The pipeline converts this into `PipelineOperationProgress`, which associates the progress with the current phase.

```swift
PipelineOperationProgress(
    completed: 25,
    total: 100,
    phase: phase
)
```

### Progress semantics

Progress belongs to the currently executing phase.

When a new phase begins, progress from the previous phase is cleared.

A terminal state retains the most recently reported progress for the phase. This means a completed or cancelled operation can still expose the last known progress.

For example:

```text
Phase: downloading
Progress: 50 / 100

        ↓

Phase: parsing
Progress: nil
```

If parsing subsequently reports progress:

```text
Phase: parsing
Progress: 25 / 50
```

---

## Observing an Operation

Operations expose their lifecycle through an `AsyncThrowingStream`:

```swift
for try await event in operation.events() {
    guard case let .stateChanged(state) = event else {
        continue
    }

    print(state.status)
    print(state.metadata?.phase as Any)
    print(state.progress as Any)
}
```

The event stream reports phase state transitions.

A phase normally produces:

```text
running
running + progress
running + progress
...
completed
```

The operation itself does not emit a separate operation-level completion event. Instead, successful completion is represented by termination of the event stream.

### Late observers

Event observation is stateful.

If an observer subscribes after an operation has already completed, failed, or been cancelled, the stream receives the latest event and then terminates.

This allows consumers to safely begin observing without needing to know exactly when the operation started.

---

## Operation State

Each state event contains a `PipelineOperationStateValue`:

```swift
public struct PipelineOperationStateValue: Sendable, Equatable {
    public let metadata: PipelineOperationMetadata?
    public let progress: PipelineOperationProgress?
    public let status: Status
}
```

The status can be:

```swift
.running
.completed
.failed
.cancelled
```

Metadata identifies both the operation and current phase:

```swift
PipelineOperationMetadata(
    operation: operationKind,
    phase: phase
)
```

### Operation kind

`PipelineOperationKind` identifies the overall operation:

```swift
let kind = PipelineOperationKind(
    rawValue: "downloadLayer"
)
```

Its `displayName` converts camel-case identifiers into human-readable text.

For example:

```text
downloadLayer → Download Layer
```

### Operation phase

`PipelineOperationPhase` identifies an individual pipeline phase:

```swift
let phase = PipelineOperationPhase(
    rawValue: "saving"
)
```

Its `displayName` similarly converts the raw identifier into a human-readable name.

---

## Snapshots

For consumers that need the current state without continuously observing events, use `snapshot()`:

```swift
let snapshot = operation.snapshot()

if let phase = snapshot.currentPhase {
    print("Current phase:", phase.displayName)
}

if let progress = snapshot.progress {
    print("Progress:", progress.percentage as Any)
}

if snapshot.isFinished {
    print("Operation finished")
}
```

`PipelineOperationSnapshot` provides:

- `latestEvent`
- `currentPhase`
- `progress`
- `isFinished`

Snapshots are safe to read concurrently with operation execution.

This is useful for UI code that needs to periodically inspect state without maintaining an event-stream consumer.

---

## Cancellation

Cancellation is cooperative.

```swift
operation.cancel()
```

A cancelled operation causes:

```swift
try await operation.value()
```

to throw:

```swift
PipelineOperationError.cancelled
```

The operation also publishes a `.cancelled` state before its event stream terminates.

Cancellation should therefore be handled separately from ordinary pipeline failures:

```swift
do {
    let result = try await operation.value()
    // Use result
} catch PipelineOperationError.cancelled {
    // Operation was cancelled
} catch {
    // Pipeline failed
}
```

Pipeline steps should cooperate with Swift task cancellation. For example:

```swift
try Task.checkCancellation()
```

or cancellation-aware asynchronous APIs should be used where appropriate.

---

## Failure Handling

Errors thrown by a pipeline step propagate out of the pipeline.

For example:

```swift
PipelineStep<Context>(
    phase: PipelineOperationPhase(rawValue: "loading")
) { _, _ in
    throw MyError()
}
```

The operation:

1. Publishes the current phase as `.failed`.
2. Terminates the event stream with the original error.
3. Rethrows the original error from `value()`.

The pipeline does not replace application-specific errors with a generic failure type.

```swift
do {
    _ = try await operation.value()
} catch {
    // Receives the original error thrown by the pipeline step.
}
```

A failed operation does not subsequently publish `.completed`.

---

## Type Erasure

`AnyPipeline<Output>` provides type erasure for pipelines whose context type should not be exposed to the caller.

```swift
let pipeline: AnyPipeline<Int> = AnyPipeline(
    Pipeline<MyContext, Int>(
        operation: PipelineOperationKind(
            rawValue: "calculate"
        ),
        context: MyContext()
    ) {
        // steps
    } output: {
        $0.value
    }
)
```

The erased pipeline exposes only:

```swift
let operation = pipeline.execute()
```

This is useful when a factory or higher-level API should return a pipeline without exposing the implementation-specific context type.

---

## Architecture

The package intentionally separates pipeline definition from operation state and reporting.

```text
Pipeline
   │
   │ execute()
   ▼
PipelineOperationState
   │
   ├── Task<Output, Error>
   │
   └── PipelineOperationReporterStorage
           │
           ├── Events
           ├── Progress
           ├── Snapshot
           └── Lifecycle state
```

During execution:

```text
Pipeline
   │
   ├── Step 1 ──► PipelineExecution.run()
   │
   ├── Step 2 ──► PipelineExecution.run()
   │
   └── Step 3 ──► PipelineExecution.run()
                         │
                         ▼
                 PipelineOperationReporter
                         │
                         ▼
                  Observers / Snapshot
```

`PipelineOperationReporter` is the abstraction used by `PipelineExecution` to publish operation events.

The default implementation, `PipelineOperationReporterStorage`, provides synchronized storage and supports multiple concurrent observers.

---

## Concurrency

The package is designed around Swift's strict concurrency model.

Public pipeline types are `Sendable` where appropriate, including:

- `Pipeline`
- `PipelineStep`
- `PipelineExecution`
- `PipelineOperation`
- `PipelineOperationEvent`
- `PipelineOperationStateValue`
- `PipelineOperationProgress`
- `PipelineOperationMetadata`

Pipeline contexts and outputs must also conform to `Sendable`:

```swift
Pipeline<Context, Output>
```

requires:

```swift
Context: Sendable
Output: Sendable
```

Pipeline closures are `@Sendable`, allowing pipeline execution to safely cross concurrency boundaries.

Internal operation reporting uses synchronization to safely coordinate concurrent progress updates and multiple event-stream consumers.

---

## Designing Pipeline Contexts

A context should contain the state needed to move information between pipeline phases.

For example:

```swift
struct ImportContext: Sendable {
    let data: Data
    var records: [Record]
    var savedCount: Int
}
```

A pipeline could then transform that context through several phases:

```text
download
   │
   ▼
decode
   │
   ▼
transform
   │
   ▼
save
   │
   ▼
output
```

Each phase owns its work while the context provides the shared state connecting the phases.

This keeps the pipeline framework independent from the domain being processed.

---

## Recommended Usage

The pipeline package is intended to provide orchestration, not domain-specific behavior.

A domain package might define:

```text
Domain
├── Repository
├── Local data source
├── Remote data source
└── Pipeline definition
```

while `Pipeline` provides:

```text
Pipeline package
├── Pipeline
├── PipelineStep
├── PipelineOperation
├── Lifecycle events
├── Progress reporting
├── Cancellation
└── Snapshots
```

The pipeline should therefore not need to know whether a step is downloading data, saving Core Data objects, parsing JSON, importing a layer, or performing another domain-specific task.

That knowledge belongs in the pipeline's context and steps.

---

## Example: Observing Progress

A consumer can combine `snapshot()` and `events()` depending on its needs.

For continuous observation:

```swift
let operation = pipeline.execute()

for try await event in operation.events() {
    guard case let .stateChanged(state) = event else {
        continue
    }

    switch state.status {
    case .running:
        if let progress = state.progress {
            print(
                "\(progress.phase.displayName): " +
                "\(progress.completed)/\(progress.total)"
            )
        }

    case .completed:
        print("Phase completed")

    case .failed:
        print("Pipeline failed")

    case .cancelled:
        print("Pipeline cancelled")
    }
}
```

For a one-time state check:

```swift
let snapshot = operation.snapshot()

print(snapshot.currentPhase?.displayName as Any)
print(snapshot.progress?.percentage as Any)
print(snapshot.isFinished)
```

---

## Testing

The package is designed to be tested without depending on a particular domain implementation.

Tests can provide a lightweight `PipelineOperationReporter` implementation and verify the events produced by `PipelineExecution`.

The package's test suite covers behavior including:

- Phase execution
- Progress reporting
- Sequential context transformation
- Cancellation
- Failure propagation
- Event-stream termination
- Late observation
- Snapshot state
- Retention of terminal progress
- Clearing progress between phases
- Concurrent progress updates
- Immediate operation execution
- Dropping event streams without cancelling execution
- `Sendable` operation usage

A custom reporter can be used when testing execution independently:

```swift
final class TestReporter:
    PipelineOperationReporter,
    @unchecked Sendable
{
    let kind: PipelineOperationKind

    init(kind: PipelineOperationKind) {
        self.kind = kind
    }

    func publish(_ event: PipelineOperationEvent) {
        // Record event for assertions.
    }
}
```

---

## Package Structure

The public API is centered around a small set of types:

```text
Pipeline
├── Pipeline
├── PipelineBuilder
├── PipelineStep
├── PipelineExecution
│
├── PipelineOperation
├── PipelineOperationState
├── PipelineOperationEvent
├── PipelineOperationStateValue
├── PipelineOperationSnapshot
│
├── PipelineOperationKind
├── PipelineOperationPhase
├── PipelineOperationMetadata
├── PipelineOperationProgress
│
├── PipelineOperationReporter
├── AnyPipeline
│
└── OperationProgress
```

The implementation deliberately keeps the execution model small: define steps, execute them sequentially, report state, observe if needed, and await the final result.
