import FetchOperation

public struct LayerSaveResult: Sendable, Equatable {
    public var inserted: Int
    public var updated: Int
    public var deleted: Int
    
    public var totalChanged: Int {
        inserted + updated + deleted
    }
    
    public static let empty =
    LayerSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 0,
    )
    
    public mutating func combine(with other: LayerSaveResult) {
        self.inserted += other.inserted
        self.updated += other.updated
        self.deleted += other.deleted
    }
}
