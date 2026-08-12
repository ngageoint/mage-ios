//
//  DefaultSaveResult.swift
//  FetchOperation
//
//

public struct DefaultSaveResult: Sendable, Equatable, CustomStringConvertible {
    public init(inserted: Int, updated: Int, deleted: Int) {
        self.inserted = inserted
        self.updated = updated
        self.deleted = deleted
    }
    
    public var description: String {
        "DefaultSaveResult: inserted: \(inserted), updated: \(updated), deleted: \(deleted)"
    }
    
    public var inserted: Int
    public var updated: Int
    public var deleted: Int
    
    public var totalChanged: Int {
        inserted + updated + deleted
    }
    
    public static let insert: DefaultSaveResult =
    DefaultSaveResult(
        inserted: 1,
        updated: 0,
        deleted: 0,
    )
    public static let update: DefaultSaveResult =
    DefaultSaveResult(
        inserted: 0,
        updated: 1,
        deleted: 0,
    )
    public static let delete =
    DefaultSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 1,
    )
    
    public static let empty =
    DefaultSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 0
    )
    
    public mutating func combine(with other: DefaultSaveResult) {
        self.inserted += other.inserted
        self.updated += other.updated
        self.deleted += other.deleted
    }
}
