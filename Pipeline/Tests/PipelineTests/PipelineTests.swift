import Testing
import Synchronization
@testable import Pipeline

struct PipelineTests {
    private struct TestContext: Sendable {
        var value: Int = 0
    }
    
    private final class TestPipelineOperationReporter:
        PipelineOperationReporter,
        @unchecked Sendable
    {
        let kind: PipelineOperationKind
        
        private let lock = Mutex<[PipelineOperationEvent]>([])
        
        init(kind: PipelineOperationKind) {
            self.kind = kind
        }
        
        func publish(_ event: PipelineOperationEvent) {
            lock.withLock { events in
                events.append(event)
            }
        }
        
        var events: [PipelineOperationEvent] {
            lock.withLock { $0 }
        }
    }
    
    @Test func `execution reports phase and progress through reporter`() async throws {
        let reporter = TestPipelineOperationReporter(
            kind: PipelineOperationKind(rawValue: "calculate")
        )
        
        let execution = PipelineExecution(
            reporter: reporter
        )
        
        let result = try await execution.run(
            phase: PipelineOperationPhase(rawValue: "incrementing")
        ) { progress in
            progress(
                OperationProgress(
                    completed: 5,
                    total: 10
                )
            )
            
            return 42
        }
        
        #expect(result == 42)
        #expect(reporter.events.count == 3)
        
        guard case let .stateChanged(running) = reporter.events[0] else {
            Issue.record("Expected running event")
            return
        }
        
        guard case let .stateChanged(progress) = reporter.events[1] else {
            Issue.record("Expected progress event")
            return
        }
        
        guard case let .stateChanged(completed) = reporter.events[2] else {
            Issue.record("Expected completed event")
            return
        }
        
        #expect(running.metadata?.phase == PipelineOperationPhase(rawValue: "incrementing"))
        #expect(progress.progress?.completed == 5)
        #expect(progress.progress?.total == 10)
        
        guard case .completed = completed.status else {
            Issue.record("Expected completed status")
            return
        }
    }
    
    @Test func pipelineTest() async throws {
        let progressReported = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "incrementing")
            ) { context, progress in
                var context = context
                context.value += 1
                
                progress(
                    OperationProgress(
                        completed: 50,
                        total: 100
                    )
                )
                
                progressReported.continuation.yield()
                await Task.yield()
                
                return context
            }
            
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "doubling")
            ) { context, _ in
                var context = context
                context.value *= 2
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var progressIterator = progressReported.stream.makeAsyncIterator()
        await progressIterator.next()
        
        let snapshot = operation.snapshot()
        #expect(
            snapshot.currentPhase ==
            PipelineOperationPhase(rawValue: "incrementing")
        )
        #expect(snapshot.progress?.completed == 50)
        #expect(snapshot.progress?.total == 100)
        #expect(snapshot.isFinished == false)
        
        progressReported.continuation.finish()
        
        let result = try await operation.value()
        
        #expect(result == 2)
    }
    
    @Test func cancellingPipelineThrowsCancelled() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "incrementing")
            ) { context, _ in
                started.continuation.yield()
                
                try await Task.sleep(for: .seconds(10))
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        operation.cancel()
        
        do {
            _ = try await operation.value()
            Issue.record("Expected cancellation")
        } catch {
            #expect(error is PipelineOperationError)
        }
    }
    
    @Test func `cancel while pipeline is running`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "incrementing")
            ) { context, _ in
                started.continuation.yield()
                
                try await Task.sleep(for: .seconds(10))
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        let eventsTask = Task<[PipelineOperationEvent], Error> {
            var events: [PipelineOperationEvent] = []
            
            for try await event in operation.events() {
                events.append(event)
            }
            
            return events
        }
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        operation.cancel()
        
        do {
            _ = try await operation.value()
            Issue.record("Expected cancellation")
        } catch {
            #expect(error is PipelineOperationError)
        }
        
        let events = try await eventsTask.value
        
        let snapshot = operation.snapshot()
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected cancellation event")
            return
        }
        
        guard case .cancelled = state.status else {
            Issue.record("Expected cancelled status")
            return
        }
        #expect(state.metadata != nil)
        #expect(snapshot.isFinished)
        
        #expect(
            events.allSatisfy {
                guard case let .stateChanged(state) = $0 else {
                    return true
                }
                
                if case .failed = state.status {
                    return false
                }
                
                return true
            }
        )
    }
    
    @Test func `next step clears previous step progress`() async throws {
        let firstStepStarted = AsyncStream.makeStream(of: Void.self)
        let secondStepStarted = AsyncStream.makeStream(of: Void.self)
        let allowSecondStepToFinish = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "first")
            ) { context, progress in
                firstStepStarted.continuation.yield()
                
                progress(
                    OperationProgress(
                        completed: 10,
                        total: 10
                    )
                )
                
                return context
            }
            
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "second")
            ) { context, _ in
                secondStepStarted.continuation.yield()
                
                var iterator = allowSecondStepToFinish.stream.makeAsyncIterator()
                await iterator.next()
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var firstIterator = firstStepStarted.stream.makeAsyncIterator()
        await firstIterator.next()
        firstStepStarted.continuation.finish()
        
        var secondIterator = secondStepStarted.stream.makeAsyncIterator()
        await secondIterator.next()
        secondStepStarted.continuation.finish()
        
        let snapshot = operation.snapshot()
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected a stateChanged event")
            return
        }
        
        guard case .running = state.status else {
            Issue.record("Expected running status")
            return
        }
        #expect(state.metadata?.phase == PipelineOperationPhase(rawValue: "second"))
        #expect(snapshot.progress == nil)
        
        allowSecondStepToFinish.continuation.yield(())
        allowSecondStepToFinish.continuation.finish()
        
        _ = try await operation.value()
    }
    
    @Test func `late observer receives latest event and terminates`() async throws {
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "incrementing")
            ) { context, _ in
                context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        _ = try await operation.value()
        
        var events: [PipelineOperationEvent] = []
        
        for try await event in operation.events() {
            events.append(event)
        }
        
        #expect(events.count == 1)
        
        guard case let .stateChanged(state) = events.last else {
            Issue.record("Expected final stateChanged event")
            return
        }
        
        guard case .completed = state.status else {
            Issue.record("Expected completed status")
            return
        }
    }
    
    @Test func `operation starts immediately without observation`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, _ in
                started.continuation.yield(())
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var iterator = started.stream.makeAsyncIterator()
        
        // If execute() didn't start the operation immediately,
        // this would hang.
        await iterator.next()
        
        started.continuation.finish()
        
        let value = try await operation.value()
        
        #expect(value == 0)
        #expect(operation.snapshot().isFinished)
    }
    
    @Test func `dropping event stream does not cancel operation`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        let allowFinish = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, _ in
                started.continuation.yield(())
                
                var iterator = allowFinish.stream.makeAsyncIterator()
                await iterator.next()
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var startedIterator = started.stream.makeAsyncIterator()
        await startedIterator.next()
        
        started.continuation.finish()
        
        // Create an observation and immediately discard it.
        let events = operation.events()
        _ = events
        
        allowFinish.continuation.yield(())
        allowFinish.continuation.finish()
        
        let value = try await operation.value()
        
        #expect(value == 0)
        #expect(operation.snapshot().isFinished)
    }
    
    
    @Test func `value preserves original failure`() async throws {
        struct TestError: Error, Equatable {}
        
        let expectedError = TestError()
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { _, _ in
                throw expectedError
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        do {
            _ = try await operation.value()
            Issue.record("Expected operation to fail")
        } catch let error as TestError {
            #expect(error == expectedError)
        } catch {
            Issue.record("Expected TestError, got \(error)")
        }
        
        let snapshot = operation.snapshot()
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected final state event")
            return
        }
        
        #expect(state.status == .failed)
        #expect(snapshot.isFinished)
    }
    
    @Test func `cancellation emits cancelled and not failed or completed`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        let allowFinish = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, _ in
                started.continuation.yield(())
                
                var iterator = allowFinish.stream.makeAsyncIterator()
                await iterator.next()
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        let eventsTask = Task<[PipelineOperationEvent], Error> {
            var events: [PipelineOperationEvent] = []
            
            do {
                for try await event in operation.events() {
                    events.append(event)
                }
            } catch {
                Issue.record("Cancellation should not terminate events with an error")
            }
            
            return events
        }
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        operation.cancel()
        
        do {
            _ = try await operation.value()
            Issue.record("Expected cancellation")
        } catch let error as PipelineOperationError {
            #expect(error == .cancelled)
        } catch {
            Issue.record("Expected PipelineOperationError.cancelled, got \(error)")
        }
        
        let events = try await eventsTask.value
        
        let states = events.compactMap { event -> PipelineOperationStateValue? in
            guard case let .stateChanged(state) = event else {
                return nil
            }
            
            return state
        }
        
        #expect(
            states.filter {
                if case .cancelled = $0.status {
                    return true
                }
                
                return false
            }.count == 1
        )
        
        #expect(
            states.allSatisfy {
                switch $0.status {
                case .running:
                    return true
                case .cancelled:
                    return true
                case .completed, .failed:
                    return false
                }
            }
        )
        
        #expect(operation.snapshot().isFinished)
    }
    
    @Test func `cancellation retains latest progress`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, progress in
                started.continuation.yield(())
                
                progress(
                    OperationProgress(
                        completed: 5,
                        total: 10
                    )
                )
                
                while !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(10))
                }
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        #expect(operation.snapshot().progress?.completed == 5)
        #expect(operation.snapshot().progress?.total == 10)
        
        operation.cancel()
        
        do {
            _ = try await operation.value()
            Issue.record("Expected cancellation")
        } catch let error as PipelineOperationError {
            #expect(error == .cancelled)
        }
        
        let snapshot = operation.snapshot()
        
        #expect(snapshot.progress?.completed == 5)
        #expect(snapshot.progress?.total == 10)
        #expect(snapshot.progress?.phase == .init(rawValue: "calculating"))
        #expect(snapshot.isFinished)
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected final state event")
            return
        }
        
        #expect(state.status == .cancelled)
    }
    
    @Test func `concurrent progress updates are safe`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, progress in
                started.continuation.yield(())
                
                await withTaskGroup(of: Void.self) { group in
                    for index in 1...100 {
                        group.addTask {
                            progress(
                                OperationProgress(
                                    completed: Int64(index),
                                    total: 100
                                )
                            )
                        }
                    }
                }
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        _ = try await operation.value()
        
        let snapshot = operation.snapshot()
        
        #expect(snapshot.isFinished)
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected final state event")
            return
        }
        
        #expect(state.status == .completed)
        #expect(state.metadata?.phase == .init(rawValue: "calculating"))
        #expect(state.progress?.phase == .init(rawValue: "calculating"))
    }
    
    @Test func `completed event retains latest progress`() async throws {
        let started = AsyncStream.makeStream(of: Void.self)
        
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, progress in
                started.continuation.yield(())
                
                progress(
                    OperationProgress(
                        completed: 10,
                        total: 10
                    )
                )
                
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        started.continuation.finish()
        
        _ = try await operation.value()
        
        let snapshot = operation.snapshot()
        
        guard case let .stateChanged(state) = snapshot.latestEvent else {
            Issue.record("Expected final state event")
            return
        }
        
        #expect(state.status == .completed)
        #expect(state.progress?.completed == 10)
        #expect(state.progress?.total == 10)
        #expect(state.progress?.phase == .init(rawValue: "calculating"))
    }
    
    @Test func `operation is sendable`() async throws {
        let pipeline = Pipeline<TestContext, Int>(
            operation: PipelineOperationKind(rawValue: "calculate"),
            context: TestContext()
        ) {
            PipelineStep<TestContext>(
                phase: PipelineOperationPhase(rawValue: "calculating")
            ) { context, _ in
                return context
            }
        } output: {
            $0.value
        }
        
        let operation = pipeline.execute()
        
        let task = Task {
            try await operation.value()
        }
        
        let value = try await task.value
        
        #expect(value == 0)
    }
}
