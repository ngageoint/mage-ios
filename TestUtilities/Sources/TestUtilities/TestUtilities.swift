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
    
    public static func urlForFile(_ filename: String, withExtension: String? = nil) -> URL? {
        return Bundle.module.url(forResource: filename, withExtension: withExtension)
    }
    
    public static func loadJSON<T: Decodable>(filename: String, fileExtension: String = "json", type: T.Type) -> T? {
        guard let url = TestUtilities.urlForFile(filename, withExtension: fileExtension) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
            
        } catch {
            return nil
        }
    }
    
    // can have extra keys means dictionary 2 can have more keys than 1
    public static func deepCompareDictionaries(dict1: [AnyHashable: Any], dict2: [AnyHashable: Any], canHaveExtraKeys: Bool = true, debugLog: Bool = false) -> Bool {
        if !canHaveExtraKeys && dict1.count != dict2.count {
            if debugLog { print("-------------- Dictionary counts are not the same --------------") }
            return false
        }
        
        var equal = true
        for (key, value1) in dict1 {
            guard let value2 = dict2[key] else {
                if debugLog { print("-------------- Dictionary2 does not have value for \(key) Dictionary1 value is \(value1) --------------") }
                equal = false
                continue
            }
            if debugLog { print("Comparing \(key): \(value1) and \(value2)") }
            
            // Recursive comparison for nested dictionaries
            if let nestedDict1 = value1 as? [AnyHashable: Any],
               let nestedDict2 = value2 as? [AnyHashable: Any] {
                if !TestUtilities.deepCompareDictionaries(dict1: nestedDict1, dict2: nestedDict2, canHaveExtraKeys: canHaveExtraKeys, debugLog: debugLog) {
                    if debugLog { print("Dictionaries are not equal") }
                    equal = false
                }
            }
            // Comparison for arrays
            else if let array1 = value1 as? [Any],
                    let array2 = value2 as? [Any] {
                if !TestUtilities.deepCompareArrays(array1: array1, array2: array2, canHaveExtraKeys: canHaveExtraKeys, debugLog: debugLog) {
                    if debugLog { print("Arrays are not equal") }
                    equal = false
                }
            } else {
                // Comparison for Equatable types
                if "millis" == key as? String {
                    print("Millis")
                }
                equal = TestUtilities.compare(value1: value1, value2: value2, debugLog: debugLog) && equal
            }
        }
        return equal
    }
    
    public static func compare(value1: Any, value2: Any, debugLog: Bool = false) -> Bool {
        if let equatableValue1 = value1 as? Int,
           let equatableValue2 = value2 as? Int
        {
            if !(equatableValue1  == equatableValue2) {
                if debugLog { print("--------- Value1: \(value1) is not equal to Value2: \(value2) --------------") }
                return false
            }
        } else if let equatableValue1 = value1 as? Double,
                  let equatableValue2 = value2 as? Double
        {
            if !(equatableValue1.closeTo(equatableValue2)) {
                if debugLog { print("--------- Value1: \(value1) is not close to Value2: \(value2) --------------") }
                return false
            }
        } else if let equatableValue1 = value1 as? Float,
                  let equatableValue2 = value2 as? Float
        {
            if !(Double(equatableValue1).closeTo(Double(equatableValue2))) {
                if debugLog { print("--------- Value1: \(value1) is not close to Value2: \(value2) --------------") }
                return false
            }
        } else if let equatableValue1 = value1 as? Float,
                  let equatableValue2 = value2 as? Double
        {
            if !(Double(equatableValue1).closeTo(equatableValue2)) {
                if debugLog { print("--------- Value1: \(value1) is not close to Value2: \(value2) --------------") }
                return false
            }
        } else if let equatableValue1 = value1 as? Double,
                  let equatableValue2 = value2 as? Float
        {
            if !(Double(equatableValue1).closeTo(Double(equatableValue2))) {
                if debugLog { print("--------- Value1: \(value1) is not close to Value2: \(value2) --------------") }
                return false
            }
        } else if let equatableValue1 = value1 as? String,
                  let equatableValue2 = value2 as? String
        {
            if !(equatableValue1 == equatableValue2) {
                if debugLog { print("--------- Value1: \(value1) is not equal to Value2: \(value2) --------------") }
                return false
            }
        }
        else if let equatableValue1 = value1 as? (any Equatable),
                let equatableValue2 = value2 as? (any Equatable)
        {
            if !(equatableValue1.isEqual(equatableValue2)) {
                if debugLog { print("--------- Value1: \(value1) is not equal to Value2: \(value2) --------------") }
                return false
            }
        }
        else if let dictionary = value1 as? [AnyHashable: Any],
                let dictionary2 = value2 as? [AnyHashable: Any]
        {
            if !deepCompareDictionaries(dict1: dictionary, dict2: dictionary2, debugLog: debugLog) {
                if debugLog { print("--------- Dictionaries are unequal --------------") }
                return false
            }
        }
        else {
            print("--------- Can't compare \(value1) and \(value2) --------------")
            return false
        }
        return true
    }
    
    public static func deepCompareArrays(array1: [Any], array2: [Any], canHaveExtraKeys: Bool = true, debugLog: Bool = false) -> Bool {
        guard array1.count == array2.count else { return false }
        for (value1, value2) in zip(array1, array2) {
            if let dict1 = value1 as? [AnyHashable: Any], let dict2 = value2 as? [AnyHashable: Any] {
                if !TestUtilities.deepCompareDictionaries(dict1: dict1, dict2: dict2, canHaveExtraKeys: canHaveExtraKeys, debugLog: debugLog) {
                    return false
                }
            } else {
                if !TestUtilities.compare(value1: value1, value2: value2, debugLog: debugLog) {
                    return false
                }
            }
        }
        return true
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


public extension Double {
    /// Checks if two Double values are close to each other within a given tolerance.
    /// - Parameters:
    ///   - other: The other Double value to compare against.
    ///   - tolerance: The maximum allowed absolute difference for the values to be considered close.
    ///                Defaults to a small value (e.g., 0.000001).
    /// - Returns: `true` if the absolute difference between the two Doubles is less than the tolerance,
    ///            `false` otherwise.
    func closeTo(_ other: Double, tolerance: Double = 0.0001) -> Bool {
        return abs(self - other) < tolerance
    }
}

public extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}
