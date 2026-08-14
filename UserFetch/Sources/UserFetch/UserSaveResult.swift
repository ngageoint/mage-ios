//
//  UserSaveResult.swift
//  UserFetch
//
//  Created by Daniel Barela on 8/4/26.
//

import FetchOperation

public struct UserSaveResult: Sendable {
    public init(saveCount: Int) {
        self.saveCount = saveCount
    }
    
    public var saveCount: Int
}
