import Foundation
import Persistence
import CoreData
import Testing

public class TestUtilities {
    public static func pathForFile(_ filename: String, withExtension: String? = nil) -> String? {
        for bundle in Bundle.allBundles {
            let path = bundle.path(forResource: filename, ofType: withExtension)
            if path != nil {
                return path
            }
        }
        return Bundle.module.path(forResource: filename, ofType: withExtension)
    }
    
    @MainActor
    public static func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval, message: String) async {
        let startTime = Date()
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                Issue.record(Comment(rawValue: message))
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        }
    }
    
    @MainActor
    public static func waitForCondition(_ condition: @escaping () async -> Bool, timeout: TimeInterval, message: String) async {
        let startTime = Date()
        while !(await condition()) {
            if Date().timeIntervalSince(startTime) > timeout {
                Issue.record(Comment(rawValue: message))
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        }
    }
}

// Don't do this in real code, only for tests
final class SendablePredicateWrapper: @unchecked Sendable {
    private let predicate: NSPredicate?
    private let lock = NSLock()
    
    init(predicate: NSPredicate?) {
        self.predicate = predicate
    }
    
    func getPredicate() -> NSPredicate? {
        lock.lock()
        defer { lock.unlock() }
        // Safely access the predicate within the lock
        return predicate
    }
}

public class PersistenceTestUtilities {
    public static func waitForCountOfEntity<T: NSManagedObject>(
        _ persistence: PersistenceProtocol,
        _ entityClass: T.Type,
        _ count: Int,
        predicate: NSPredicate? = nil
    ) async {
        let uncheckedPredicate = SendablePredicateWrapper(predicate: predicate)
        await confirmation("\(entityClass) count does not equal \(count)") { [persistence, uncheckedPredicate] confirm in
            let startTime = Date()
            var currentCount: Int = -1
            var correctCount = false
            while !correctCount {
                currentCount = await persistence.read { [uncheckedPredicate] context in
                    return (try? context.countOfObjectsNotPending(entityClass, predicate: uncheckedPredicate.getPredicate())) ?? -1
                }
                print("Count is now \(currentCount)")
                correctCount = currentCount == count
                if Date().timeIntervalSince(startTime) > 2 {
                    Issue.record("Timeout waiting for count to be \(count), it is \(currentCount)")
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds delay
            }
            confirm()
        }
    }
}

extension NSManagedObjectContext {
    func countOfObjectsNotPending<T: NSManagedObject>(_ entityClass: T.Type, predicate: NSPredicate? = nil) throws -> Int? {
        guard let request: NSFetchRequest<T> = entityClass.fetchRequest() as? NSFetchRequest<T> else {
            return nil
        }
        request.includesPendingChanges = false
        request.predicate = predicate
        return try self.count(for: request)
    }
}
