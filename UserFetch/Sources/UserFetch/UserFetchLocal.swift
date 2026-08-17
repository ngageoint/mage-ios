//
//  UserFetchLocal.swift
//  UserFetch
//
//

import ServerDTO
import FetchOperation

public protocol UserFetchLocal: FetchLocalDataSource where DTO == UserDTO, SaveResult == UserSaveResult {
}
