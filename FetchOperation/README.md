# FetchOperation

`FetchOperation` provides fetch-specific building blocks on top of the generic [`Pipeline`](../Pipeline) framework.

It defines the abstractions needed to model data fetching as a sequence of asynchronous phases while keeping networking, persistence, and domain models outside the framework.

A typical fetch looks like:

```text
FetchRepository
       │
       ▼
  FetchPipeline
       │
       ├── Download
       │
       ├── Save
       │
       └── Custom Steps
       │
       ▼
     Output
```

Each call to `startFetch()` creates and immediately starts a new pipeline operation.

The returned `PipelineOperation` can then be:

- Awaited with `value()`
- Observed with `events()`
- Inspected with `snapshot()`
- Cancelled with `cancel()`

## Requirements

- Swift 6.3+
- iOS 18+
- Swift language mode 6

## Dependencies

`FetchOperation` depends on:

- `Pipeline` — generic pipeline execution, lifecycle, progress, cancellation, and observation
- `ProgressReportingJSONDecoder` — available for progress-aware decoding steps

The package intentionally does not depend on a networking framework or persistence framework.

---

# Architecture

`FetchOperation` sits between domain-specific repositories and the generic pipeline engine.

```text
┌─────────────────────────────┐
│       Domain Repository     │
│                             │
│  creates/configures fetch   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      FetchRepository        │
│                             │
│      startFetch()           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          Pipeline           │
│                             │
│   Download → Save → ...     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      PipelineOperation      │
│                             │
│ value() / events() /        │
│ snapshot() / cancel()       │
└─────────────────────────────┘
```

The important architectural boundary is that `FetchOperation` knows about **fetch concepts**, while `Pipeline` knows only about **generic pipeline execution**.

For example:

- `FetchRemoteDataSource` is fetch-specific.
- `FetchLocalDataSource` is fetch-specific.
- `.downloading` and `.saving` are fetch-specific phases.
- `PipelineStep` and `PipelineOperation` are generic.

This allows the same pipeline engine to be reused for operations that are not fetches.

---

# FetchRepository

`FetchRepository` owns an erased pipeline and creates a new operation for each fetch.

```swift
let repository = FetchRepository(
    pipeline: AnyPipeline(pipeline)
)

let operation = repository.startFetch()
```

Repositories are reusable.

Each call to `startFetch()` creates a new operation:

```swift
let first = repository.startFetch()
let second = repository.startFetch()
```

These are independent executions of the same pipeline definition.

## FetchRepositoryProtocol

Repositories can also be represented through the protocol:

```swift
public protocol FetchRepositoryProtocol<Output>: Sendable {
    associatedtype Output: Sendable

    func startFetch()
        -> any PipelineOperation<Output>
}
```

This allows domain-specific repository implementations to expose fetch behavior without exposing their concrete implementation.

---

# AnyFetchRepository

`AnyFetchRepository` provides type erasure for `FetchRepositoryProtocol`.

```swift
let repository = AnyFetchRepository(
    concreteRepository
)
```

The resulting repository exposes only the fetch operation:

```swift
let operation = repository.startFetch()
```

This is useful when a factory or dependency container needs to return a repository without exposing its concrete repository type.

---

# FetchRemoteDataSource

Remote fetching is represented by `FetchRemoteDataSource`.

```swift
public protocol FetchRemoteDataSource: Sendable {

    associatedtype DTO: Sendable

    func fetch(
        urlRequest: URLRequest?,
        progress: @escaping OperationProgressHandler
    ) async throws -> [DTO]
}
```

A remote data source owns the actual transport implementation.

For example:

```swift
struct UserRemote: FetchRemoteDataSource {

    func fetch(
        urlRequest: URLRequest?,
        progress: @escaping OperationProgressHandler
    ) async throws -> [UserDTO] {

        // Perform network request...

        return users
    }
}
```

The fetch framework does not require a particular HTTP client.

The implementation can use `URLSession`, Alamofire, or another transport mechanism.

The framework only requires the data source to return DTOs and report progress.

### URL Request

A remote data source receives an optional `URLRequest`.

```swift
func fetch(
    urlRequest: URLRequest?,
    progress: @escaping OperationProgressHandler
) async throws -> [UserDTO]
```

This allows a pipeline context to carry request-specific information without coupling the pipeline to a networking implementation.

---

# FetchLocalDataSource

Persistence is represented by `FetchLocalDataSource`.

```swift
public protocol FetchLocalDataSource: Sendable {

    associatedtype DTO: Sendable
    associatedtype SaveResult: Sendable

    @discardableResult
    func save(
        _ dto: [DTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult
}
```

The local data source owns persistence behavior.

For example:

```swift
struct UserLocal: FetchLocalDataSource {

    func save(
        _ dto: [UserDTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {

        // Persist users...

        return result
    }
}
```

Like the remote data source, the local implementation is completely independent of the framework.

---

# FetchPipelineContext

`FetchPipelineContext` is the standard context for fetch pipelines.

```swift
public struct FetchPipelineContext<
    DTO: Sendable,
    SaveResult: Sendable
>: Sendable,
   DTOContext,
   URLRequestContext,
   SaveResultContext
```

It contains:

```swift
public var urlRequest: URLRequest?
public var dto: [DTO]
public var saveResult: SaveResult?
```

The context allows information to flow between pipeline phases.

For example:

```text
┌────────────────────┐
│ FetchPipelineContext│
│                    │
│ urlRequest         │
│ dto                │
│ saveResult         │
└────────────────────┘
         │
         ▼
    Download step
         │
         │ dto
         ▼
      Save step
         │
         │ saveResult
         ▼
      Output
```

The context is `Sendable`, so all values stored in it must also be `Sendable`.

---

# Context Protocols

The framework provides small protocols that allow custom contexts to expose only the capabilities required by a step.

## DTOContext

```swift
public protocol DTOContext: Sendable {
    associatedtype DTO: Sendable
    var dto: [DTO] { get set }
}
```

A context conforming to `DTOContext` can carry decoded or downloaded DTOs.

## URLRequestContext

```swift
public protocol URLRequestContext: Sendable {
    var urlRequest: URLRequest? { get set }
}
```

A context conforming to `URLRequestContext` can carry the request used by a remote data source.

## SaveResultContext

```swift
public protocol SaveResultContext: Sendable {
    associatedtype SaveResult: Sendable
    var saveResult: SaveResult? { get set }
}
```

A context conforming to `SaveResultContext` can carry the result of persistence.

## DataContext

```swift
public protocol DataContext: Sendable {
    var data: Data { get set }
}
```

`DataContext` provides a context capability for pipelines that operate on raw downloaded data.

These protocols allow pipeline steps to be constrained by the capabilities they actually require rather than by a single concrete context type.

---

# Fetch Pipeline Steps

Fetch-specific convenience steps are provided as extensions to `PipelineStep`.

## Download

A context conforming to `DTOContext & URLRequestContext` can use:

```swift
PipelineStep.download(
    remote: remote
)
```

The step:

1. Reads `urlRequest` from the context.
2. Calls the remote data source.
3. Stores the resulting DTOs in `context.dto`.
4. Reports progress through the pipeline.
5. Returns the updated context.

Conceptually:

```text
Context
   │
   │ urlRequest
   ▼
Remote
   │
   │ [DTO]
   ▼
Context.dto
```

## Save

A context conforming to `DTOContext & SaveResultContext` can use:

```swift
PipelineStep.save(
    local: local
)
```

The step:

1. Reads DTOs from `context.dto`.
2. Passes them to the local data source.
3. Stores the resulting save result in `context.saveResult`.
4. Reports progress.
5. Returns the updated context.

Conceptually:

```text
Context.dto
     │
     ▼
   Local
     │
     │ SaveResult
     ▼
Context.saveResult
```

## Decode

A decoding step is available for contexts conforming to:

```swift
DTOContext & DataContext
```

The implementation is intended to support progress-reporting JSON decoding through `ProgressReportingJSONDecoder`.

---

# Fetch Phases

`FetchOperation` defines standard phases on `PipelineOperationPhase`:

```swift
.downloading
.saving
.syncing
.preparing
.parsing
```

These are conventions rather than restrictions. Custom pipelines can use additional phases.

For example:

```swift
PipelineOperationPhase(
    rawValue: "validating"
)
```

The phase identifies what work is currently being performed and is included in operation metadata and progress.

---

# Default Fetch Pipeline

For the common case of downloading DTOs and saving them locally, `FetchPipelines.default` creates the pipeline automatically.

```swift
let pipeline = FetchPipelines.default(
    remote: remote,
    local: local,
    operation: PipelineOperationKind(
        rawValue: "users"
    )
)
```

The resulting pipeline is equivalent to:

```text
Download
    │
    ▼
Save
    │
    ▼
[DTO]
```

The output is the DTO collection:

```swift
Pipeline<
    FetchPipelineContext<Remote.DTO, Local.SaveResult>,
    [Remote.DTO]
>
```

The remote and local data sources must use the same DTO type.

---

# Complete Example

A typical fetch repository can be assembled as follows.

## Remote

```swift
struct UserRemote: FetchRemoteDataSource {

    func fetch(
        urlRequest: URLRequest?,
        progress: @escaping OperationProgressHandler
    ) async throws -> [UserDTO] {

        // Fetch users from the server.

        return users
    }
}
```

## Local

```swift
struct UserLocal: FetchLocalDataSource {

    func save(
        _ dto: [UserDTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> DefaultSaveResult {

        // Save users locally.

        return result
    }
}
```

## Pipeline

```swift
let pipeline = FetchPipelines.default(
    remote: UserRemote(),
    local: UserLocal(),
    operation: PipelineOperationKind(
        rawValue: "users"
    )
)
```

## Repository

```swift
let repository = FetchRepository(
    pipeline: AnyPipeline(pipeline)
)
```

## Execute

```swift
let operation = repository.startFetch()

let users = try await operation.value()
```

The fetch begins immediately when `startFetch()` returns.

---

# Observing a Fetch

The returned operation exposes the generic `PipelineOperation` API.

```swift
let operation = repository.startFetch()

for try await event in operation.events() {
    guard case let .stateChanged(state) = event else {
        continue
    }

    print(
        state.metadata?.phase.displayName as Any
    )

    if let progress = state.progress {
        print(
            "\(progress.completed)/\(progress.total)"
        )
    }

    print(state.status)
}
```

Observation is independent of execution.

The operation continues even if no consumer observes its events.

Multiple consumers can observe the same operation:

```swift
let operation = repository.startFetch()

let observer1 = Task {
    for try await event in operation.events() {
        // UI observer
    }
}

let observer2 = Task {
    for try await event in operation.events() {
        // Logging observer
    }
}
```

---

# Awaiting the Result

The simplest usage is to ignore events and await the result:

```swift
let operation = repository.startFetch()

do {
    let users = try await operation.value()

    // Use users.
} catch {
    // Handle failure.
}
```

This is appropriate when progress and lifecycle events are not required.

---

# Snapshots

A current operation state can be retrieved without subscribing to the event stream:

```swift
let snapshot = operation.snapshot()

if let phase = snapshot.currentPhase {
    print("Current phase: \(phase.displayName)")
}

if let progress = snapshot.progress {
    print("Progress: \(progress.percentage as Any)")
}

if snapshot.isFinished {
    print("Finished")
}
```

Snapshots are useful for UI state reconstruction or one-time inspection.

---

# Cancellation

Cancellation is explicitly requested through the operation:

```swift
operation.cancel()
```

The underlying pipeline uses Swift task cancellation.

Cancellation is cooperative, so remote and local implementations should use cancellation-aware asynchronous APIs and check cancellation where appropriate.

For example:

```swift
try Task.checkCancellation()
```

A cancelled operation ultimately reports the cancellation through the underlying `PipelineOperation`.

---

# Progress

Both remote and local data sources receive a progress callback:

```swift
@escaping OperationProgressHandler
```

Report progress as work completes:

```swift
progress(
    OperationProgress(
        completed: completed,
        total: total
    )
)
```

The generic `Pipeline` package associates that progress with the currently executing fetch phase.

This keeps progress reporting independent from UI frameworks.

A data source does not need to know whether its progress will be displayed in:

- SwiftUI
- UIKit
- A command-line client
- Logging
- Tests
- No consumer at all

---

# DefaultSaveResult

`DefaultSaveResult` is a convenience save result for local data sources that need to report inserted, updated, and deleted counts.

```swift
let result = DefaultSaveResult(
    inserted: 10,
    updated: 5,
    deleted: 2
)
```

It provides:

```swift
result.inserted
result.updated
result.deleted
result.totalChanged
```

It can also be combined:

```swift
var result = DefaultSaveResult.empty

result.combine(
    with: DefaultSaveResult(
        inserted: 10,
        updated: 2,
        deleted: 1
    )
)
```

Convenience values are provided for individual changes:

```swift
DefaultSaveResult.insert
DefaultSaveResult.update
DefaultSaveResult.delete
DefaultSaveResult.empty
```

Applications that need different save semantics can define their own `SaveResult` type.

---

# Custom Pipelines

`FetchPipelines.default` is intentionally limited to the common download/save workflow.

More complex fetches should define their own pipeline.

For example:

```swift
let pipeline = Pipeline<
    FetchPipelineContext<UserDTO, DefaultSaveResult>,
    [UserDTO]
>(
    operation: PipelineOperationKind(
        rawValue: "users"
    ),
    context: FetchPipelineContext()
) {
    PipelineStep.download(
        remote: remote
    )

    PipelineStep(
        phase: .preparing
    ) { context, _ in

        // Transform or validate context.

        return context
    }

    PipelineStep.save(
        local: local
    )
} output: {
    $0.dto
}
```

This allows a repository to model more complex workflows without adding special cases to `FetchOperation`.

For example:

```text
Download
   │
   ▼
Prepare
   │
   ▼
Parse
   │
   ▼
Validate
   │
   ▼
Save
   │
   ▼
Output
```

---

# Custom Contexts

The standard `FetchPipelineContext` is not required.

A custom context can combine only the capabilities needed by a particular fetch:

```swift
struct UserFetchContext: Sendable,
                          DTOContext,
                          URLRequestContext,
                          SaveResultContext {

    typealias DTO = UserDTO
    typealias SaveResult = DefaultSaveResult

    var urlRequest: URLRequest?
    var dto: [UserDTO] = []
    var saveResult: DefaultSaveResult?
}
```

This can be useful when a fetch requires additional state:

```swift
struct UserFetchContext: Sendable,
                          DTOContext,
                          URLRequestContext,
                          SaveResultContext {

    typealias DTO = UserDTO
    typealias SaveResult = DefaultSaveResult

    var urlRequest: URLRequest?
    var dto: [UserDTO] = []
    var saveResult: DefaultSaveResult?

    var deletedUserIDs: [String] = []
    var validationErrors: [String] = []
}
```

The context remains domain-specific while the pipeline engine remains generic.

---

# Concurrency

The package is designed for Swift 6 strict concurrency.

Fetch-related protocols and contexts are `Sendable`, and remote/local implementations must also be `Sendable`.

For example:

```swift
public protocol FetchRemoteDataSource: Sendable
```

and:

```swift
public protocol FetchLocalDataSource: Sendable
```

This prevents non-sendable dependencies from accidentally crossing concurrency boundaries.

The returned `PipelineOperation` can be safely shared between concurrent tasks:

```swift
let operation = repository.startFetch()

let resultTask = Task {
    try await operation.value()
}

let snapshotTask = Task {
    operation.snapshot()
}

let result = try await resultTask.value
```

---

# Transport and Persistence Independence

`FetchOperation` does not perform networking or persistence itself.

Instead, it defines boundaries:

```text
                 FetchOperation
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
 FetchRemoteDataSource     FetchLocalDataSource
          │                         │
          ▼                         ▼
      HTTP/API                 Core Data/etc.
```

This keeps infrastructure decisions outside the package.

For example, a remote data source can use:

- `URLSession`
- Alamofire
- A mock implementation
- An in-memory implementation

Likewise, a local data source can use:

- Core Data
- SQLite
- A file store
- An in-memory implementation

The fetch pipeline does not need to know which implementation is being used.

---

# Relationship to Pipeline

`Pipeline` is the generic execution framework.

`FetchOperation` specializes that framework for data-fetch workflows.

```text
Pipeline
│
├── Pipeline
├── PipelineStep
├── PipelineOperation
├── PipelineOperationEvent
├── PipelineOperationSnapshot
├── Progress
├── Cancellation
└── Observation

             ▲
             │
             │ builds on
             │
FetchOperation
│
├── FetchRepository
├── FetchRepositoryProtocol
├── AnyFetchRepository
├── FetchRemoteDataSource
├── FetchLocalDataSource
├── FetchPipelineContext
├── DTOContext
├── URLRequestContext
├── DataContext
├── SaveResultContext
├── Fetch-specific steps
├── Fetch-specific phases
└── DefaultSaveResult
```

The separation is intentional.

A repository should not need to understand the implementation details of the generic pipeline execution engine. It can simply construct or receive a pipeline and expose `startFetch()`.

---

# Design Goals

`FetchOperation` is intended to provide:

- A consistent abstraction for asynchronous fetches
- Strong separation between repositories and data sources
- Transport-independent remote fetching
- Persistence-independent local saving
- Reusable pipeline definitions
- Strongly typed pipeline contexts
- Progress reporting without UI dependencies
- Structured concurrency
- Cooperative cancellation
- Multiple concurrent observers
- Snapshot-based state inspection
- Type-erased repositories and pipelines where useful

The package deliberately avoids owning domain behavior.

A domain-specific package should decide:

- What is being fetched
- How requests are constructed
- How remote data is decoded
- How data is persisted
- What the domain output should be
- What additional pipeline phases are required

`FetchOperation` provides the infrastructure for composing those behaviors into a consistent asynchronous operation.
