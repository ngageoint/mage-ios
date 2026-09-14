import Foundation
import CoreData

public extension NSManagedObjectContext {
    func fetchFirst <T: NSManagedObject>(_ entityClass: T.Type,
                                         sortBy: [NSSortDescriptor]? = nil,
                                         predicate: NSPredicate? = nil) throws -> T? {
        let result = try self.fetchObjects(entityClass, sortBy: sortBy, fetchLimit: 1, predicate: predicate)
        return result?.first
    }
    
    func fetchAll<T: NSManagedObject>(_ entityClass: T.Type) -> [T]? {
        return try? self.fetchObjects(entityClass)
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
    
    func deleteAll<T: NSManagedObject>(_ entityClass: T.Type, matching: NSPredicate) -> Int {
        let objects = (try? fetchObjects(entityClass, predicate: matching)) ?? []
        for object in objects{
            self.delete(object)
        }
        return objects.count
    }
}
