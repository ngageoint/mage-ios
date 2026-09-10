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
import LocationFetch
import Form
import LayerFetch
import EventFetch
import Event

struct AppDependencies {
    let settingsRepository: SettingsRepository
    let settingsFetch: AnyFetchRepository<Void, [MapSettingsDTO]>
    let userRepository: UserRepository
    let userFetch: AnyFetchRepository<UserFetchRequest, [UserDTO]>
    let locationFetch: AnyFetchRepository<LocationFetchRequest, LocationRepositoryFetchResult>
    let formIconFetch: AnyFetchRepository<FormIconFetchRequest, [URL]>
    let layerFetch: AnyFetchRepository<LayerFetchRequest, [MapLayerDTO]>
    let staticLayerDataFetch: AnyFetchRepository<StaticLayerDataFetchRequest, StaticLayerRepositoryFetchResult>
    let eventRepository: EventRepository
    let eventFetch: AnyFetchRepository<Void, EventRepositoryFetchResult>
}
