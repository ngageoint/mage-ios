//
//  UserFetchLocal.swift
//  UserFetch
//
//  Created by Daniel Barela on 8/4/26.
//

import ServerDTO
import FetchOperation

public protocol UserFetchLocal: FetchLocalDataSource where DTO == UserDTO, SaveResult == UserSaveResult {
}
