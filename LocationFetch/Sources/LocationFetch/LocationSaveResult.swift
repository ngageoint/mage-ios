//
//  LocationSaveResult.swift
//  LocationFetch
//
//

import FetchOperation

public struct LocationSaveResult: Sendable, Equatable {
    public var inserted: Int
    public var updated: Int
    public var ignored: Int
    public var deleted: Int
    public var missingUserIds: Set<String> = []
}

public extension LocationSaveResult {
    static let delete =
    LocationSaveResult(
        inserted: 0,
        updated: 0,
        ignored: 0,
        deleted: 1,
        missingUserIds: []
    )
    
    static let empty =
    LocationSaveResult(
        inserted: 0,
        updated: 0,
        ignored: 0,
        deleted: 0,
        missingUserIds: []
    )
    
    mutating func combine(with other: LocationSaveResult) {
        self.inserted += other.inserted
        self.updated += other.updated
        self.deleted += other.deleted
        self.ignored += other.ignored
        self.missingUserIds
            .formUnion(other.missingUserIds
                .compactMap { $0 })
    }
}
