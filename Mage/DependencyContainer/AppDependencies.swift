// 
//     
//  AppDependencies.swift
//  MAGE
//
// 

import FetchOperation
import ServerDTO
import Settings
import UserFetch
import User

struct AppDependencies {
    let settingsRepository: SettingsRepository
    let settingsFetch: AnyFetchRepository<Void, [MapSettingsDTO]>
    let userRepository: UserRepository
    let userFetch: AnyFetchRepository<UserFetchRequest, [UserDTO]>
}
