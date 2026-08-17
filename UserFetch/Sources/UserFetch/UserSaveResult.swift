//
//  UserSaveResult.swift
//  UserFetch
//
//

import FetchOperation

public struct UserSaveResult: Sendable {
    public init(saveCount: Int) {
        self.saveCount = saveCount
    }
    
    public var saveCount: Int
}
