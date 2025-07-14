//
//  SettingsModel.swift
//  MAGE
//
//

import Foundation

struct SettingsModel: Equatable, Hashable {
    var mapSearchTypeCode: Int32?
    var mapSearchUrl: String?
    
    var mapSearchType: MapSearchType {
        get {
            if let mapSearchTypeCode {
                return MapSearchType(rawValue: mapSearchTypeCode) ?? .none
            }
            return .none
        }
        set {
            self.mapSearchTypeCode = newValue.rawValue
        }
    }
}

extension SettingsModel {
    init(settings: Settings) {
        mapSearchTypeCode = settings.mapSearchTypeCode
        mapSearchUrl = settings.mapSearchUrl
    }
}
