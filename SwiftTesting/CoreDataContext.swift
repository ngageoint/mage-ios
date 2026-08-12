//
//  CoreDataContext.swift
//


@testable import Persistence
@testable import MAGE
import Testing
import CoreData

public struct PersistenceContext: Sendable {
    public let persistence: PersistenceProtocol
    @TaskLocal public static var current: PersistenceContext?
}

public enum CoreDataType: Sendable {
    case coredata
    case fake(persistence: PersistenceProtocol)
}

public struct PersistenceTrait: TestTrait, TestScoping {

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent  @Sendable () async throws -> Void
    ) async throws {
        let persistence = MagicalRecordPersistence()
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
}

// Make the trait available as a static property
public extension Trait where Self == PersistenceTrait {
    static func persistence() -> Self {
        Self()
    }
}
