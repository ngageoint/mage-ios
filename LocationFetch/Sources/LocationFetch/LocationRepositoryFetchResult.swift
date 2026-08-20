//
//  LocationRepositoryFetchResult.swift
//  LocationFetch
//
//

import ServerDTO

public struct LocationRepositoryFetchResult: Sendable {
    public init(dto: [UserLocationDTO], missingUserIDs: Set<String>? = nil, inserts: Int, updates: Int) {
        self.dto = dto
        self.missingUserIDs = missingUserIDs
        self.inserts = inserts
        self.updates = updates
    }
    
    public let dto: [UserLocationDTO]
    public  let missingUserIDs: Set<String>?
    public let inserts: Int
    public  let updates: Int
}
