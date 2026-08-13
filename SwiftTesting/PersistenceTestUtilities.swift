// 
//     
//  PersistenceTestUtilities.swift
//  MAGE
//
// 

import Persistence
import CoreData
import Testing

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
    public static func waitForCountOfEntity<T: NSManagedObject>(_ persistence: PersistenceProtocol, _ entityClass: T.Type, _ count: Int, predicate: NSPredicate? = nil) async {
        let uncheckedPredicate = SendablePredicateWrapper(predicate: predicate)
        await confirmation("\(entityClass) count does not equal \(count)") { [persistence, uncheckedPredicate] confirm in
            let startTime = Date()
            var currentCount: Int = -1
            var correctCount = false
            while !correctCount {
                currentCount = await persistence.read { [uncheckedPredicate] context in
                    guard let request: NSFetchRequest<T> = entityClass.fetchRequest() as? NSFetchRequest<T> else {
                        return currentCount
                    }
                    request.includesPendingChanges = false
                    request.predicate = predicate
                    return (try? context.count(for: request)) ?? -1
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
