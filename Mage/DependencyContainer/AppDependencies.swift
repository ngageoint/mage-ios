// 
//     
//  AppDependencies.swift
//  MAGE
//
// 

import FetchOperation
import ServerDTO
import Settings

struct AppDependencies {
    let settingsRepository: SettingsRepository
    let settingsFetch: AnyFetchRepository<Void, [MapSettingsDTO]>
}
