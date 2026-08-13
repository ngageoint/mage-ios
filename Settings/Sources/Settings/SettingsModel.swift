// 
//     
//  SettingsModel.swift
//  Settings
//
// 


import Foundation
import Persistence
import ServerDTO

public struct SettingsModel: Equatable, Hashable, Sendable {
    public var mapSearchUrl: String?

    public var mapSearchType: MapSearchType
}

extension SettingsModel {
    public init(settings: Settings) {
        mapSearchType = MapSearchType(
            rawValue: settings.mapSearchTypeCode
        ) ?? .none
        mapSearchUrl = settings.mapSearchUrl
    }
}

extension SettingsModel: CoreDataDomainModelConvertible {
    public typealias Entity = Settings

    public init(from entity: Settings) {
        self.mapSearchUrl = entity.mapSearchUrl
        self.mapSearchType = entity.mapSearchType
    }
}
