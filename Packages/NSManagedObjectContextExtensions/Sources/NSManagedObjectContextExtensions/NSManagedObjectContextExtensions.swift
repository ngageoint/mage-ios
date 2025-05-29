import Foundation
import CoreData

public extension NSManagedObjectContext {
    // Execute fetch request
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T]? {
        let fetchedResult = try? self.fetch(request)
        return fetchedResult
    }
    func fetchObjects <T: NSManagedObject>(_ entityClass: T.Type,
                                           sortBy: [NSSortDescriptor]? = nil,
                                           fetchLimit: Int? = nil,
                                           predicate: NSPredicate? = nil) throws -> [T]? {
        guard let request: NSFetchRequest<T> = entityClass.fetchRequest() as? NSFetchRequest<T> else {
            return nil
        }
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        request.predicate = predicate
        request.sortDescriptors = sortBy
        let fetchedResult = try self.fetch(request)
        return fetchedResult
    }
    
    func delete<T: NSManagedObject>(object: T) {
        self.delete(object)
    }

    // Returns the count of objects for the given entity
    func countOfObjects<T: NSManagedObject>(_ entityClass: T.Type, predicate: NSPredicate? = nil) throws -> Int? {
        guard let request: NSFetchRequest<T> = entityClass.fetchRequest() as? NSFetchRequest<T> else {
            return nil
        }
        request.predicate = predicate
        return try self.count(for: request)
    }
    // Returns first object after executing fetchObjects method with given sort and predicates
    func fetchFirst <T: NSManagedObject>(_ entityClass: T.Type,
                                         sortBy: [NSSortDescriptor]? = nil,
                                         predicate: NSPredicate? = nil) throws -> T? {
        let result = try self.fetchObjects(entityClass, sortBy: sortBy, fetchLimit: 1, predicate: predicate)
        return result?.first
    }
    // Helper method to fetch first object with given key value pair.
    func fetchFirst<T: NSManagedObject>(_ entityClass: T.Type,
                                        key: String,
                                        value: String) -> T? {
        let predicate = NSPredicate(format: "%K = %@", key, value)
        return try? self.fetchFirst(
            entityClass,
            sortBy: [NSSortDescriptor(key: key, ascending: true)],
            predicate: predicate
        )
    }

    func fetchFirst<T: NSManagedObject>(_ entityClass: T.Type,
                                        key: String,
                                        value: Int) -> T? {
        let predicate = NSPredicate(format: "%K = %d", key, value)
        return try? self.fetchFirst(entityClass, sortBy: nil, predicate: predicate)
    }
    
    func fetchFirst<T: NSManagedObject>(_ entityClass: T.Type,
                                        key: String,
                                        value: NSNumber) -> T? {
        let predicate = NSPredicate(format: "%K = %@", key, value)
        return try? self.fetchFirst(entityClass, sortBy: nil, predicate: predicate)
    }

    func fetchAll<T: NSManagedObject>(_ entityClass: T.Type) -> [T]? {
        return try? self.fetchObjects(entityClass)
    }

    func truncateAll<T: NSManagedObject>(_ entityClass: T.Type) -> Bool {
        let request: NSFetchRequest<NSFetchRequestResult> =
        entityClass.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try self.persistentStoreCoordinator?.execute(deleteRequest, with: self)
        } catch _ as NSError {
            // TODO: handle the error
            return false
        }
        return true
    }
}
