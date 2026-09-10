import FetchOperation
import ServerDTO

public struct EventSaveResult: Sendable, Equatable, CustomStringConvertible {
    public var description: String {
        "EventSave: inserted: \(inserted), updated: \(updated), deleted: \(deleted)"
    }

    public var inserted: Int
    public var updated: Int
    public var deleted: Int
    
    public var totalChanged: Int {
        inserted + updated + deleted
    }
    
    public static let insert: EventSaveResult =
        EventSaveResult(
            inserted: 1,
            updated: 0,
            deleted: 0,
        )
    public static let update: EventSaveResult =
        EventSaveResult(
            inserted: 0,
            updated: 1,
            deleted: 0,
        )
    public static let delete =
    EventSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 1,
    )
    
    public static let empty =
    EventSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 0
    )
    
    public mutating func combine(with other: EventSaveResult) {
        self.inserted += other.inserted
        self.updated += other.updated
        self.deleted += other.deleted
    }
}
