//
//  CoreDataContext.swift
//


@testable import Persistence
@testable import MAGE
import Testing
import CoreData

// This is a marker for all core data tests
// they need to run serialized due to the way MagicalRecord has singletons for
// the contexts.  When MagicalRecord is removed, these tests can be allowed
// to run in parallel
@Suite(
    .serialized,
    .persistence
)
struct CoreDataTests {
}

public struct PersistenceContext: Sendable {
    public let persistence: PersistenceProtocol
    @TaskLocal public static var current: PersistenceContext?
}

public enum CoreDataType: Sendable {
    case coredata
    case fake(persistence: PersistenceProtocol)
}

public struct PersistenceTrait: TestTrait, SuiteTrait, TestScoping {

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent  @Sendable () async throws -> Void
    ) async throws {
        let persistence = MagicalRecordPersistence()
        PersistenceContainer.shared.reconfigure(persistence)
        let testContext = PersistenceContext(
            persistence: persistence
        )
        defer {
            testContext.persistence.viewContext.performAndWait {
                testContext.persistence.viewContext.reset()
            }
            
            testContext.persistence.writeContext.performAndWait {
                testContext.persistence.writeContext.reset()
            }
            persistence.tearDownStack()
        }

        try await PersistenceContext.$current.withValue(testContext) {
            try await function()
        }

    }
    
    public var isRecursive: Bool {
        true
    }
}

// Make the trait available as a static property
public extension Trait where Self == PersistenceTrait {
    static var persistence: Self {
        Self()
    }
}
