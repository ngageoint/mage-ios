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

struct AppDependencies {
    let settingsRepository: SettingsRepository
    let settingsFetch: AnyFetchRepository<Void, [MapSettingsDTO]>
    let userFetch: AnyFetchRepository<UserFetchRequest, [UserDTO]>
}
